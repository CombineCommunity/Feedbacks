//
//  Transitions.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-23.
//
import Combine

/// Represents a series of Transitions that drive a State Machine.
public struct Transitions {
    let transitions: [From]

    /// the reducer computed from the state machine's transitions
    public let reducer: (State, Event) -> State
    public let scheduledReducer: (State, AnyPublisher<Event, Never>) -> AnyPublisher<State, Never>

    /// - Parameter transitions: the individual transitions composing the state machine
    /// Transitions {
    ///     From(Loading.self) { state in
    ///       On(LoadingHasComplete.self) { event in
    ///         Loaded()
    ///       }
    ///     }
    ///     From(Loading.self) { state in
    ///       On(LoadingHasFailed.self) { event in
    ///         Failed()
    ///       }
    ///     }
    /// }
    public init(@ArrayBuilder<From> _ transitions: () -> [From]) {
        self.init(transitions: transitions())
    }

    init(transitions: [From]) {
        self.transitions = transitions
        self.reducer = Transitions.makeReducer(transitions: transitions)
        self.scheduledReducer = { [reducer] initialState, events in
            return events
                .scan(initialState, reducer)
                .eraseToAnyPublisher()
        }
    }

    init(transitions: [From],
         reducer: @escaping (State, Event) -> State,
         scheduledReducer: @escaping (State, AnyPublisher<Event, Never>) -> AnyPublisher<State, Never>) {
        self.transitions = transitions
        self.reducer = reducer
        self.scheduledReducer = scheduledReducer
    }

    static func makeReducer(transitions: [From]) -> (State, Event) -> State {
        let transitionsForStates = transitions.reduce(into: [AnyHashable: (State) -> [AnyHashable: (Event) -> State?]]()) { accumulator, from in
            let existingTranstionsForState = accumulator[from.id]
            accumulator[from.id] = { state in from.computeTransitionsForEvents(for: state, existingTranstionsForState: existingTranstionsForState) }
        }

        return { state, event -> State in
            if
                let transitionsForState = transitionsForStates[state.instanceId],
                let transitionForEvent = transitionsForState(state)[event.instanceId],
                let newState = transitionForEvent(event) { return newState }

            if
                let transitionsForState = transitionsForStates[state.instanceId],
                let transitionForEvent = transitionsForState(state)[AnyEvent.id],
                let newState = transitionForEvent(event) { return newState }

            if
                let transitionsForState = transitionsForStates[AnyState.id],
                let transitionForEvent = transitionsForState(state)[event.instanceId],
                let newState = transitionForEvent(event) { return newState }

            if
                let transitionsForState = transitionsForStates[AnyState.id],
                let transitionForEvent = transitionsForState(state)[AnyEvent.id],
                let newState = transitionForEvent(event) { return newState }

            return state
        }
    }
}

// MARK: modifiers
public extension Transitions {
    /// Disables all the transitions of the state machine, as long as the `disabled` condition is true
    /// - Parameter disabled: the condition that disables the transitions
    /// - Returns: the  transitions
    func disable(_ disabled: @escaping () -> Bool) -> Self {
        Transitions(transitions: self.transitions.map { $0.disable(disabled) })
    }

    /// Alter the scheduler on which the Transitions run. If no schedulers are
    /// set for the Transitions, then they will be executed on the current scheduler.
    /// - Parameter scheduler: the scheduler on which to execute the Transitions
    /// - Returns: The newly scheduled Transitions
    func execute<SchedulerType: Scheduler>(on scheduler: SchedulerType) -> Self {
        let newScheduledReducer: (State, AnyPublisher<Event, Never>) -> AnyPublisher<State, Never> = { [scheduledReducer] initialState, events in
            return scheduledReducer(initialState, events.receive(on: scheduler).eraseToAnyPublisher())
        }

        return Transitions(transitions: self.transitions, reducer: self.reducer, scheduledReducer: newScheduledReducer)
    }
}

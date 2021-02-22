//
//  Transitions.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-23.
//

/// Represents a series of Transitions that drive a State Machine.
public struct Transitions {
    let transitions: [From]

    /// the reducer computed from the state machine's transitions
    public let reducer: (State, Event) -> State

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
        let transitionsForStates = self.transitions.reduce(into: [AnyHashable: (State) -> [AnyHashable: (Event) -> State?]]()) { accumulator, from in
            let existingTranstionsForState = accumulator[from.id]
            accumulator[from.id] = { state in from.computeTransitionsForEvents(for: state, existingTranstionsForState: existingTranstionsForState) }
        }
        self.reducer = { state, event -> State in
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
}

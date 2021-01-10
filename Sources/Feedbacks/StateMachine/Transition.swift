//
//  Transition.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-21.
//

/// A Transition describes the passage from a State to another, in reaction to an event.
/// The pair of input state and event forms a TransitionId, which identifies the Transition within a  state machine.
/// As a TransitionId is Hashable, there cannot exist 2 Transitions with the same pair State/Event in one state machine.
/// In that case, the last declared transition will be the one executed.
public struct Transition: TransitionsDefinition, Equatable {
    let transitionId: TransitionId
    let reducer: (State, Event) -> State

    /// Build a Transition based on a State type and an Event type. The transition will produce a new state by executing the `then` reducer
    /// - Parameters:
    ///   - stateType: The type of state that is concerned by this transition
    ///   - eventType: The type of event that is concerned by this transition
    ///   - reducer: The new state factory based on the received state and event
    ///
    /// `Transition(from: LoadingState.self, on: LoadedEvent.self, then: { _, event in return LoadedState(data: event.data) })`
    public init<StateType: State, EventType: Event>(
        from stateType: StateType.Type,
        on eventType: EventType.Type,
        then reducer: @escaping (StateType, EventType) -> State) {
        self.transitionId = TransitionId(stateId: StateType.id, eventId: EventType.id)
        self.reducer = { state, event in
            guard
                let concreteState = state as? StateType,
                let concreteEvent = event as? EventType else {
                return state
            }

            return reducer(concreteState, concreteEvent)
        }
    }

    /// Build a Transition based on a State type and an Event type. The transition will produce the `newState` state
    /// - Parameters:
    ///   - stateType: The type of state that is concerned by this transition
    ///   - eventType: The type of event that is concerned by this transition
    ///   - newState: The new state
    public init<StateType: State, EventType: Event>(
        from stateType: StateType.Type,
        on eventType: EventType.Type,
        then newState: State) {
        self.init(from: stateType, on: eventType) { _, _ -> State in
            newState
        }
    }

    init(transitionId: TransitionId, reducer: @escaping (State, Event) -> State) {
        self.transitionId = transitionId
        self.reducer = reducer
    }

    public var entries: [TransitionId: (State, Event) -> State] {
        [self.transitionId: self.reducer]
    }

    public static func == (lhs: Transition, rhs: Transition) -> Bool {
        lhs.entries.map { $0.key } == rhs.entries.map { $0.key }
    }
}

// MARK: modifiers
public extension Transition {
    func disable(_ disabled: @escaping () -> Bool) -> Self {
        let disabledReducer: (State, Event) -> State = { state, event in
            guard !disabled() else { return state }
            return self.reducer(state, event)
        }

        return Transition(transitionId: self.transitionId, reducer: disabledReducer)
    }
}

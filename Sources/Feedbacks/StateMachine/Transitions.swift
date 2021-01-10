//
//  Transitions.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-23.
//

/// Represents a series of Transitions to form a State Machine.
public struct Transitions: TransitionsDefinition {
    let transitions: [TransitionsDefinition]

    /// - Parameter transitions: the individual transitions composing the state machine
    /// `Transitions {`
    ///     `Transition(from: LoadingState.self, on: LoadedEvent.self, then: LoadedState())`
    ///     `Transition(from: LoadingState.self, on: ErrorEvent.self, then: ErrorState())`
    /// `}`
    public init(@TransitionsDefinitionsBuilder _ transitions: () -> [TransitionsDefinition]) {
        self.transitions = transitions()
    }

    init(transitions: [TransitionsDefinition]) {
        self.transitions = transitions
    }

    public var entries: [TransitionId: (State, Event) -> State] {
        self.transitions.reduce(into: [TransitionId: (State, Event) -> State]()) { accumulator, transition in
            accumulator.merge(transition.entries, uniquingKeysWith: { $1 })
        }
    }
}

// MARK: modifiers
public extension Transitions {
    func disable(_ disabled: @escaping () -> Bool) -> Self {
        let disabledTransitions = self.transitions.map { $0.disable(disabled) }

        return Transitions(transitions: disabledTransitions)
    }
}

public extension Transitions {
    var reducer: (State, Event) -> State {
        let entries = self.entries

        return { state, event -> State in
            let transitionId = TransitionId(stateId: state.instanceId, eventId: event.instanceId)

            if let reducer = entries[transitionId] {
                return reducer(state, event)
            }

            let transitionAnyEventId = TransitionId(stateId: state.instanceId, eventId: AnyEvent.id)
            if let reducer = entries[transitionAnyEventId] {
                return reducer(state, AnyEvent())
            }

            let transitionAnyStateId = TransitionId(stateId: AnyState.id, eventId: event.instanceId)
            if let reducer = entries[transitionAnyStateId] {
                return reducer(AnyState(), event)
            }

            let transitionAnyId = TransitionId(stateId: AnyState.id, eventId: AnyEvent.id)
            if let reducer = entries[transitionAnyId] {
                return reducer(AnyState(), AnyEvent())
            }

            return state
        }
    }
}

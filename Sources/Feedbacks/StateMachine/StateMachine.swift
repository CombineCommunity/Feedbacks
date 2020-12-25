//
//  StateMachine.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-23.
//

public struct StateMachine: Transitions {
    public let entries: [TransitionId: (State, Event) -> State]

    public init(@TransitionsBuilder _ transitions: () -> [Transitions]) {
        self.entries = transitions().reduce(into: [TransitionId: (State, Event) -> State]()) { accumulator, transition in
            accumulator.merge(transition.entries, uniquingKeysWith: { $1 })
        }
    }
}

public extension StateMachine {
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

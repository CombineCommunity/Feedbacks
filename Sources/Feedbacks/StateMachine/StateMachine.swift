//
//  StateMachine.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-23.
//

public protocol StateMachineDefinition: Transitions {
    @TransitionsBuilder var transitions: [Transitions] { get }
}

public struct StateMachine: StateMachineDefinition {
    public let transitions: [Transitions]

    public init(@TransitionsBuilder _ transitions: () -> [Transitions]) {
        self.transitions = transitions()
    }
}

public extension StateMachineDefinition {
    var entries: [TransitionId: (State, Event) -> State] {
        self.transitions.reduce([TransitionId: (State, Event) -> State](),
                                { accumulator, transition -> [TransitionId: (State, Event) -> State] in
                                    accumulator.merging(transition.entries, uniquingKeysWith: { $1 })
                                })
    }

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

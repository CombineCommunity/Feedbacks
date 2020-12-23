//
//  Transition.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-21.
//

public struct Transition: Transitions, Equatable {
    public var entries = [TransitionId: (State, Event) -> State]()

    public init<StateType: State, EventType: Event>(
        from stateType: StateType.Type,
        on eventType: EventType.Type,
        then reducer: @escaping (StateType, EventType) -> State) {
        let id = TransitionId(stateId: StateType.id, eventId: EventType.id)
        let reducer: (State, Event) -> State = { state, event in
            guard
                let concreteState = state as? StateType,
                let concreteEvent = event as? EventType else {
                return state
            }

            return reducer(concreteState, concreteEvent)
        }
        self.entries[id] = reducer
    }

    public init<StateType: State, EventType: Event>(
        from stateType: StateType.Type,
        on eventType: EventType.Type,
        then newState: State) {
        self.init(from: stateType, on: eventType) { _, _ -> State in
            newState
        }
    }

    public static func == (lhs: Transition, rhs: Transition) -> Bool {
        lhs.entries.map { $0.key } == rhs.entries.map { $0.key }
    }
}

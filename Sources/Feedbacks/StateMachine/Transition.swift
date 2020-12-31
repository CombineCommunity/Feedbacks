//
//  Transition.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-21.
//

public struct Transition: Transitions, Equatable {
    let transitionId: TransitionId
    let reducer: (State, Event) -> State

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

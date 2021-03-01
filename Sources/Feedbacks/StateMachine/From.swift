//
//  From.swift
//  
//
//  Created by Thibault Wittemberg on 2021-02-21.
//

/// `From` represent the state that a transition will use as the basis for a new state
public struct From {
    let id: AnyHashable
    let transitionsForState: (State) -> [On]

    /// Build a transition for a State type
    /// - Parameters:
    ///   - stateType: the type of state for which transitions are possible
    ///   - transitionsForState: the possible transitions for the type of state
    public init<StateType: State>(_ stateType: StateType.Type,
                                  @ArrayBuilder<On> _ transitionsForState: @escaping (StateType) -> [On]) {
        self.init(id: StateType.id) { state in
            guard let concreteState = state as? StateType else { return [] }
            return transitionsForState(concreteState)
        }
    }

    /// Build a transition for a State type
    /// - Parameters:
    ///   - stateType: the type of state for which transitions are possible
    ///   - transitionsForState: the possible transitions for the type of state (not based on the current state)
    public init<StateType: State>(_ stateType: StateType.Type,
                                  @ArrayBuilder<On> _ transitionsForState: @escaping () -> [On]) {
        self.init(id: StateType.id) { state in
            guard state is StateType else { return [] }
            return transitionsForState()
        }
    }

    /// Build a transition for a any state
    /// - Parameters:
    ///   - stateType: the wildcard for any state
    ///   - transitionsForState: the possible transitions for any state
    public init(_ stateType: AnyState.Type,
                @ArrayBuilder<On> _ transitionsForState: @escaping (State) -> [On]) {
        self.init(id: AnyState.id, transitions: transitionsForState)
    }

    /// Build a transition for a any state
    /// - Parameters:
    ///   - stateType: the wildcard for any state
    ///   - transitionsForState: the possible transitions for any state (not based on the current state)
    public init(_ stateType: AnyState.Type,
                @ArrayBuilder<On> _ transitionsForState: @escaping () -> [On]) {
        self.init(id: AnyState.id, transitions: { _ in transitionsForState() })
    }

    init(id: AnyHashable, transitions: @escaping (State) -> [On]) {
        self.id = id
        self.transitionsForState = transitions
    }

    func computeTransitionsForEvents(for state: State, existingTranstionsForState: ((State) -> [AnyHashable: (Event) -> State?])? = nil) -> [AnyHashable: (Event) -> State?] {
        var transitionsForEvents = self.transitionsForState(state).reduce(into: [AnyHashable: (Event) -> State?]()) { accumulator, on in
            accumulator[on.id] = on.transitionForEvent
        }

        if let existingTransitionsForEvents = existingTranstionsForState?(state) {
            transitionsForEvents.merge(existingTransitionsForEvents, uniquingKeysWith: { value1, value2 in value2 })
        }

        return transitionsForEvents
    }
}

public extension From {
    /// Disables the transitions for this state type, as long as the `disabled` condition is true
    /// - Parameter disabled: the condition that disables the transitions
    /// - Returns: the `From` transition
    func disable(_ disabled: @escaping () -> Bool) -> Self {
        From(id: self.id) { state -> [On] in
            return self.transitionsForState(state).map { $0.disable(disabled) }
        }
    }
}

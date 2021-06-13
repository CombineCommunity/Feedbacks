//
//  On.swift
//  
//
//  Created by Thibault Wittemberg on 2021-02-21.
//

/// `On` represent the input that the state machine will react to.
public struct On {
    let eventId: AnyHashable
    let outputStateId: AnyHashable
    let transitionForEvent: (Event) -> State?

    /// Build a transition for an Event Type
    /// - Parameters:
    ///   - eventType: The event type that should trigger the transition
    ///   - transition: the transition to compute a new state based on the received event
    public init<EventType: Event, StateType: State>(_ eventType: EventType.Type,
                                                    transitionTo: StateType.Type,
                                                    _ transition: @escaping (EventType) -> StateType) {
        self.eventId = EventType.id
        self.outputStateId = StateType.id
        self.transitionForEvent = { event in
            guard let concreteEvent = event as? EventType else { return nil }
            return transition(concreteEvent)
        }
    }

    /// Build a transition for an Event Type
    /// - Parameters:
    ///   - eventType: The event type that should trigger the transition
    ///   - transition: the transition to compute a new state
    public init<EventType: Event, StateType: State>(_ eventType: EventType.Type,
                                                    transitionTo: StateType.Type,
                                                    _ transition: @escaping () -> StateType) {
        self.eventId = EventType.id
        self.outputStateId = StateType.id
        self.transitionForEvent = { event in
            guard event is EventType else { return nil }
            return transition()
        }
    }

    /// Build a transition for an Event Type
    /// - Parameters:
    ///   - eventType: The event type that should trigger the transition
    ///   - transitionTo: the new state
    public init<EventType: Event, StateType: State>(_ eventType: EventType.Type, transitionTo: StateType) {
        self.eventId = EventType.id
        self.outputStateId = StateType.id
        self.transitionForEvent = { event in
            guard event is EventType else { return nil }
            return transitionTo
        }
    }

    /// Build a transition for any event
    /// - Parameters:
    ///   - eventType: the wildcard for any event
    ///   - transition: the transition to compute a new state based on the received event
    public init<StateType: State>(_ eventType: AnyEvent.Type,
                                  transitionTo: StateType.Type,
                                  _ transition: @escaping (Event) -> StateType) {
        self.eventId = AnyEvent.id
        self.outputStateId = StateType.id
        self.transitionForEvent = transition
    }

    /// Build a transition for any event
    /// - Parameters:
    ///   - eventType: the wildcard for any event
    ///   - transition: the transition to compute a new state based on the received event
    public init<StateType: State>(_ eventType: AnyEvent.Type,
                                  transitionTo: StateType.Type,
                                  _ transition: @escaping () -> StateType) {
        self.eventId = AnyEvent.id
        self.outputStateId = StateType.id
        self.transitionForEvent = { _ in
            transition()
        }
    }

    /// Build a transition for any event
    /// - Parameters:
    ///   - eventType: the wildcard for any event
    ///   - transitionTo: the new state
    public init<StateType: State>(_ eventType: AnyEvent.Type, transitionTo: StateType) {
        self.eventId = AnyEvent.id
        self.outputStateId = StateType.id
        self.transitionForEvent = { _ in
            transitionTo
        }
    }

    init(eventId: AnyHashable, outputId: AnyHashable, transition: @escaping (Event) -> State?) {
        self.eventId = eventId
        self.outputStateId = outputId
        self.transitionForEvent = transition
    }
}

public extension On {
    /// Disables the transition as long as the `disabled` condition is true
    /// - Parameter disabled: the condition that disables the transition
    /// - Returns: the `On` transition
    func disable(_ disabled: @escaping () -> Bool) -> Self {
        On(eventId: self.eventId, outputId: self.outputStateId) { event -> State? in
            guard !disabled() else { return nil }
            return self.transitionForEvent(event)
        }
    }
}

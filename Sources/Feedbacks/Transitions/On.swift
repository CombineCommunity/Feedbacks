//
//  On.swift
//  
//
//  Created by Thibault Wittemberg on 2021-02-21.
//

/// `On` represent the input that the state machine will react to.
public struct On {
    let id: AnyHashable
    let transitionForEvent: (Event) -> State?

    /// Build a transition for an Event Type
    /// - Parameters:
    ///   - eventType: The event type that should trigger the transition
    ///   - transition: the transition to compute a new state based on the received event
    public init<EventType: Event> (_ eventType: EventType.Type, transition: @escaping (EventType) -> State) {
        self.id = EventType.id
        self.transitionForEvent = { event in
            guard let concreteEvent = event as? EventType else { return nil }
            return transition(concreteEvent)
        }
    }

    /// Build a transition for an Event Type
    /// - Parameters:
    ///   - eventType: The event type that should trigger the transition
    ///   - transition: the transition to compute a new state
    public init<EventType: Event> (_ eventType: EventType.Type, transition: @escaping () -> State) {
        self.id = EventType.id
        self.transitionForEvent = { event in
            guard event is EventType else { return nil }
            return transition()
        }
    }

    /// Build a transition for an Event Type
    /// - Parameters:
    ///   - eventType: The event type that should trigger the transition
    ///   - transitionTo: the new state
    public init<EventType: Event> (_ eventType: EventType.Type, transitionTo: State) {
        self.id = EventType.id
        self.transitionForEvent = { event in
            guard event is EventType else { return nil }
            return transitionTo
        }
    }

    /// Build a transition for any event
    /// - Parameters:
    ///   - eventType: the wildcard for any event
    ///   - transition: the transition to compute a new state based on the received event
    public init (_ eventType: AnyEvent.Type, transition: @escaping (Event) -> State) {
        self.id = AnyEvent.id
        self.transitionForEvent = transition
    }

    /// Build a transition for any event
    /// - Parameters:
    ///   - eventType: the wildcard for any event
    ///   - transition: the transition to compute a new state based on the received event
    public init (_ eventType: AnyEvent.Type, transition: @escaping () -> State) {
        self.id = AnyEvent.id
        self.transitionForEvent = { _ in
            transition()
        }
    }

    /// Build a transition for any event
    /// - Parameters:
    ///   - eventType: the wildcard for any event
    ///   - transitionTo: the new state
    public init (_ eventType: AnyEvent.Type, transitionTo: State) {
        self.id = AnyEvent.id
        self.transitionForEvent = { _ in
            transitionTo
        }
    }

    init(id: AnyHashable, transition: @escaping (Event) -> State?) {
        self.id = id
        self.transitionForEvent = transition
    }
}

public extension On {
    /// Disables the transition as long as the `disabled` condition is true
    /// - Parameter disabled: the condition that disables the transition
    /// - Returns: the `On` transition
    func disable(_ disabled: @escaping () -> Bool) -> Self {
        On(id: self.id) { event -> State? in
            guard !disabled() else { return nil }
            return self.transitionForEvent(event)
        }
    }
}

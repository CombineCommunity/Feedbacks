//
//  Transitions.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-23.
//

public struct TransitionId: Hashable {
    let stateId: AnyHashable
    let eventId: AnyHashable

    public init(stateId: AnyHashable, eventId: AnyHashable) {
        self.stateId = stateId
        self.eventId = eventId
    }
}

public protocol Transitions {
    var entries: [TransitionId: (State, Event) -> State] { get }
    func disable(_ disabled: @escaping () -> Bool) -> Self
}

@_functionBuilder
public struct TransitionsBuilder {
    public static func buildBlock(_ transitions: Transitions...) -> [Transitions] {
        transitions
    }
}

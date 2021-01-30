//
//  CanEmitEvent.swift
//  
//
//  Created by Thibault Wittemberg on 2021-01-30.
//

import Combine

public protocol CanEmitEvent  {
    var events: PassthroughSubject<Event, Never> { get }
    func emit(_ event: Event)
}

public extension CanEmitEvent {
    func emit(_ event: Event) {
        self.events.send(event)
    }
}

//
//  CounterApp+SideEffects.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-12.
//

import Combine
import Feedbacks
import Foundation

// define a namespace for this app's feedbacks
extension CounterApp {
    enum SideEffects {}
}

extension CounterApp.SideEffects {
    // This effect will make the state decrease when it is already decreasing and not paused
    // When the state is equal to 0, then the effect asks for an increase
    static func decreaseEffect(state: CounterApp.States.Decreasing) -> AnyPublisher<Event, Never> {
        guard !state.isPaused else { return Empty().eraseToAnyPublisher() }

        if state.value > 0 {
            return Just<Event>(CounterApp.Events.Decrease())
                .delay(for: 1, scheduler: DispatchQueue(label: UUID().uuidString))
                .eraseToAnyPublisher()
        }

        return Just<Event>(CounterApp.Events.Increase())
            .delay(for: 1, scheduler: DispatchQueue(label: UUID().uuidString))
            .eraseToAnyPublisher()
    }

    // This effect will make the state increase when it is already increasing and not paused
    // When the state is equal to 10, then the effect asks for a decrease
    static func increaseEffect(state: CounterApp.States.Increasing) -> AnyPublisher<Event, Never> {
        guard !state.isPaused else { return Empty().eraseToAnyPublisher() }

        if state.value < 10 {
            return Just<Event>(CounterApp.Events.Increase())
                .delay(for: 1, scheduler: DispatchQueue(label: UUID().uuidString))
                .eraseToAnyPublisher()
        }

        return Just<Event>(CounterApp.Events.Decrease())
            .delay(for: 1, scheduler: DispatchQueue(label: UUID().uuidString))
            .eraseToAnyPublisher()
    }
}

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
    static func decreaseEffect(state: CounterApp.States.Decreasing) -> AnyPublisher<Event, Never> {
        guard !state.isPaused else { return Empty().eraseToAnyPublisher() }

        if state.counter.value <= state.counter.min {
            return Just<Event>(CounterApp.Events.Increase())
                .delay(for: 1, scheduler: DispatchQueue(label: UUID().uuidString))
                .eraseToAnyPublisher()
        }

        return Just<Event>(CounterApp.Events.Decrease())
            .delay(for: 1, scheduler: DispatchQueue(label: UUID().uuidString))
            .eraseToAnyPublisher()
    }

    // This effect will make the state increase when it is already increasing and not paused
    static func increaseEffect(state: CounterApp.States.Increasing) -> AnyPublisher<Event, Never> {
        guard !state.isPaused else { return Empty().eraseToAnyPublisher() }

        if state.counter.value >= state.counter.max {
            return Just<Event>(CounterApp.Events.Decrease())
                .delay(for: 1, scheduler: DispatchQueue(label: UUID().uuidString))
                .eraseToAnyPublisher()
        }

        return Just<Event>(CounterApp.Events.Increase())
            .delay(for: 1, scheduler: DispatchQueue(label: UUID().uuidString))
            .eraseToAnyPublisher()
    }
}

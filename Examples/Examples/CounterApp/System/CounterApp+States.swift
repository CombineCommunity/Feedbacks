//
//  CounterApp+States.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-12.
//

import Feedbacks

// define a namespace for this app's states
extension CounterApp {
    enum States {}
}

extension CounterApp.States {
    struct Fixed: State, Equatable {
        let counter: Counter
    }

    struct Increasing: State, Equatable {
        let counter: Counter
        let isPaused: Bool
    }

    struct Decreasing: State, Equatable {
        let counter: Counter
        let isPaused: Bool
    }
}

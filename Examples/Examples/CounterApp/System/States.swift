//
//  States.swift
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
    struct Fixed: State {
        let value: Int
    }

    struct Increasing: State {
        let value: Int
        let isPaused: Bool
    }

    struct Decreasing: State {
        let value: Int
        let isPaused: Bool
    }
}

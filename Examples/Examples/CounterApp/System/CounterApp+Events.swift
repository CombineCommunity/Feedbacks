//
//  CounterApp+Events.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-12.
//

import Feedbacks

// define a namespace for this app's events
extension CounterApp {
    enum Events {}
}

extension CounterApp.Events {
    struct TogglePause: Event {}

    struct Reset: Event {
        let value: Int
    }

    struct Increase: Event {}

    struct Decrease: Event {}
}


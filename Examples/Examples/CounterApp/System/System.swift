//
//  System.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-12.
//

import Feedbacks

// define a namespace for this app's system
extension CounterApp {
    enum System {}
}

extension CounterApp.System {
    static let counter = System {
        InitialState {
            CounterApp.States.Fixed(value: 10)
        }

        Feedbacks {
            Feedback(strategy: .cancelOnNewState, sideEffect: CounterApp.SideEffects.decreaseEffect(state:))
            Feedback(strategy: .cancelOnNewState, sideEffect: CounterApp.SideEffects.increaseEffect(state:))
        }
        .onStateReceived {
            print("New state has been received: \($0)")
        }
        .onEventEmitted {
            print("New event has been triggered: \($0)")
        }

        Transitions {
            CounterApp.Transitions.fixedTransitions
            CounterApp.Transitions.resetTransitions
            CounterApp.Transitions.decreasingTransitions
            CounterApp.Transitions.increasingTransitions
        }
    }
}
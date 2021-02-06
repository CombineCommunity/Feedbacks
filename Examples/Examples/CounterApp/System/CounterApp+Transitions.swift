//
//  CounterApp+Transitions.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-12.
//

import Feedbacks

// define a namespace for this app's transitions
extension CounterApp {
    enum Transitions {}
}

extension CounterApp.Transitions {
    static let fixedTransition = Transition(from: CounterApp.States.Fixed.self,
                                             on: CounterApp.Events.TogglePause.self) { state, _ -> State in
        CounterApp.States.Decreasing(value: state.value, isPaused: false)
    }

    static let resetTransition = Transition(from: AnyState.self, on: CounterApp.Events.Reset.self) { _, event -> State in
        CounterApp.States.Fixed(value: event.value)
    }

    static let decreasingTransitions = Transitions {
        Transition(from: CounterApp.States.Decreasing.self, on: CounterApp.Events.TogglePause.self) { state, _ -> State in
            CounterApp.States.Decreasing(value: state.value, isPaused: !state.isPaused)
        }

        Transition(from: CounterApp.States.Decreasing.self, on: CounterApp.Events.Decrease.self) { state, _ -> State in
            guard !state.isPaused else { return state }
            return CounterApp.States.Decreasing(value: state.value - 1, isPaused: false)
        }

        Transition(from: CounterApp.States.Decreasing.self, on: CounterApp.Events.Increase.self) { state, _ -> State in
            guard !state.isPaused else { return state }
            return CounterApp.States.Increasing(value: state.value + 1, isPaused: false)
        }
    }

    static let increasingTransitions = Transitions {
        Transition(from: CounterApp.States.Increasing.self, on: CounterApp.Events.TogglePause.self) { state, _ -> State in
            CounterApp.States.Increasing(value: state.value, isPaused: !state.isPaused)
        }

        Transition(from: CounterApp.States.Increasing.self, on: CounterApp.Events.Decrease.self) { state, _ -> State in
            guard !state.isPaused else { return state }
            return CounterApp.States.Decreasing(value: state.value - 1, isPaused: false)
        }

        Transition(from: CounterApp.States.Increasing.self, on: CounterApp.Events.Increase.self) { state, _ -> State in
            guard !state.isPaused else { return state }
            return CounterApp.States.Increasing(value: state.value + 1, isPaused: false)
        }
    }
}

//
//  CounterApp+System.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-12.
//

import Dispatch
import Feedbacks

// define a namespace for this app's system
extension CounterApp {
    enum System {}
}

extension CounterApp.System {
    static let counter = System {
        InitialState {
            CounterApp.States.Fixed(counter: Counter(value: 10, min: 0, max: 10))
        }

        Feedbacks {
            Feedback(on: CounterApp.States.Decreasing.self,
                     strategy: .cancelOnNewState,
                     perform: CounterApp.SideEffects.decreaseEffect(state:))

            Feedback(on: CounterApp.States.Increasing.self,
                     strategy: .cancelOnNewState,
                     perform: CounterApp.SideEffects.increaseEffect(state:))
        }
        .onStateReceived {
            print("Counter: New state has been received: \($0)")
        }
        .onEventEmitted {
            print("Counter: New event has been triggered: \($0)")
        }

        Transitions {
            From(CounterApp.States.Fixed.self) { state in
                On(CounterApp.Events.TogglePause.self, transitionTo: CounterApp.States.Decreasing(counter: state.counter, isPaused: false))
            }

            From(AnyState.self) {
                On(CounterApp.Events.Reset.self, transitionTo: CounterApp.States.Fixed(counter: Counter(value: 10, min: 0, max: 10)))
            }

            From(CounterApp.States.Decreasing.self) { state in
                On(CounterApp.Events.TogglePause.self, transitionTo: CounterApp.States.Decreasing(counter: state.counter, isPaused: !state.isPaused))
                On(CounterApp.Events.Decrease.self, transitionTo: CounterApp.States.Decreasing(counter: state.counter.decrease(), isPaused: false))
                On(CounterApp.Events.Increase.self, transitionTo: CounterApp.States.Increasing(counter: state.counter.increase(), isPaused: false))
            }

            From(CounterApp.States.Increasing.self) { state in
                On(CounterApp.Events.TogglePause.self, transitionTo: CounterApp.States.Increasing(counter: state.counter, isPaused: !state.isPaused))
                On(CounterApp.Events.Increase.self, transitionTo: CounterApp.States.Increasing(counter: state.counter.increase(), isPaused: false))
                On(CounterApp.Events.Decrease.self, transitionTo: CounterApp.States.Decreasing(counter: state.counter.decrease(), isPaused: false))
            }
        }
    }.execute(on: DispatchQueue(label: "Counter Queue"))
}

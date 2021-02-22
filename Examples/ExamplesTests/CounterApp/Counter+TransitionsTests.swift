//
//  ExamplesTests.swift
//  ExamplesTests
//
//  Created by Thibault Wittemberg on 2021-02-28.
//

@testable import Examples
import Feedbacks
import FeedbacksTest
import XCTest

final class ExamplesTests: XCTestCase {
    let mockCounter = Counter(value: 5, min: 0, max: 10)
    let shouldIncreaseMockCounter = Counter(value: 0, min: 0, max: 10)
    let shouldDecreaseMockCounter = Counter(value: 10, min: 0, max: 10)

    func testTransitions_fromFixed_onToggle() {
        CounterApp.Transitions.counterTransitions.assertThat(
            from: CounterApp.States.Fixed(counter: mockCounter),
            on: CounterApp.Events.TogglePause(),
            newStateIs: CounterApp.States.Decreasing(counter: mockCounter, isPaused: false)
        )
    }

    func testTransitions_fromDecreasing_onToggle() {
        CounterApp.Transitions.counterTransitions.assertThat(
            from: CounterApp.States.Decreasing(counter: mockCounter, isPaused: false),
            on: CounterApp.Events.TogglePause(),
            newStateIs: CounterApp.States.Decreasing(counter: mockCounter, isPaused: true)
        )
    }

    func testTransitions_fromDecreasing_onDecrease() {
        CounterApp.Transitions.counterTransitions.assertThat(
            from: CounterApp.States.Decreasing(counter: mockCounter, isPaused: false),
            on: CounterApp.Events.Decrease(),
            newStateIs: CounterApp.States.Decreasing(counter: mockCounter.decrease(), isPaused: false)
        )
    }

    func testTransitions_fromDecreasing_onDecrease_when_at_min() {
        CounterApp.Transitions.counterTransitions.assertThat(
            from: CounterApp.States.Decreasing(counter: shouldIncreaseMockCounter, isPaused: false),
            on: CounterApp.Events.Decrease(),
            newStateIs: CounterApp.States.Increasing(counter: shouldIncreaseMockCounter.increase(), isPaused: false)
        )
    }

    func testTransitions_fromIncreasing_onToggle() {
        CounterApp.Transitions.counterTransitions.assertThat(
            from: CounterApp.States.Increasing(counter: mockCounter, isPaused: false),
            on: CounterApp.Events.TogglePause(),
            newStateIs: CounterApp.States.Increasing(counter: mockCounter, isPaused: true)
        )
    }

    func testTransitions_fromIncreasing_onIncrease() {
        CounterApp.Transitions.counterTransitions.assertThat(
            from: CounterApp.States.Increasing(counter: mockCounter, isPaused: false),
            on: CounterApp.Events.Increase(),
            newStateIs: CounterApp.States.Increasing(counter: mockCounter.increase(), isPaused: false)
        )
    }

    func testTransitions_fromIncreasing_onIncrease_when_at_max() {
        CounterApp.Transitions.counterTransitions.assertThat(
            from: CounterApp.States.Increasing(counter: shouldDecreaseMockCounter, isPaused: false),
            on: CounterApp.Events.Increase(),
            newStateIs: CounterApp.States.Decreasing(counter: shouldDecreaseMockCounter.decrease(), isPaused: false)
        )
    }

    func testTransitions_fromAny_onRefresh() {
        let allStates: [State] = [
            CounterApp.States.Fixed(counter: mockCounter),
            CounterApp.States.Decreasing(counter: mockCounter, isPaused: false),
            CounterApp.States.Increasing(counter: mockCounter, isPaused: false)
        ]
        allStates.forEach {
            CounterApp.Transitions.counterTransitions.assertThat(from: $0,
                                                                 on: CounterApp.Events.Reset(),
                                                                 newStateIs: CounterApp.States.Fixed(counter: Counter(value: 10, min: 0, max: 10)))
        }
    }
}

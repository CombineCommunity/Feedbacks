//
//  TransitionsTests.swift
//
//
//  Created by Thibault Wittemberg on 2020-12-24.
//

import Feedbacks
import FeedbacksTest
import XCTest

private struct MockState: State, Equatable { let value: Int }
private struct AnotherMockState: State, Equatable { let value: Int }

private struct MockEvent: Event, Equatable { let value: Int }
private struct AnotherMockEvent: Event {}

final class TransitionsTests: XCTestCase {
    func testReducer_handles_the_combination_of_registered_and_not_registered_states_and_events() {
        // Given: some transitions that handles registered states and events and also any states and any events
        let expectedState1 = MockState(value: 1)
        let expectedState2 = MockState(value: 2)
        let expectedState3 = MockState(value: 3)
        let expectedState4 = MockState(value: 4)

        let sut = Transitions {
            From(MockState.self) {
                On(MockEvent.self, transitionTo: expectedState1)
                On(AnyEvent.self, transitionTo: expectedState2)
            }

            From(AnyState.self) {
                On(MockEvent.self, transitionTo: expectedState3)
                On(AnyEvent.self, transitionTo: expectedState4)
            }
        }

        // When: reducing all the combinations are registers / not registered states and events
        // Then: the reducer handles all the cases with the expected priority
        sut.assertThat(from: MockState(value: 1), on: MockEvent(value: 1), newStateIs: expectedState1)
        sut.assertThat(from: MockState(value: 1), on: AnotherMockEvent(), newStateIs: expectedState2)
        sut.assertThat(from: AnotherMockState(value: 2), on: MockEvent(value: 1), newStateIs: expectedState3)
        sut.assertThat(from: AnotherMockState(value: 2), on: AnotherMockEvent(), newStateIs: expectedState4)
    }

    func testReducer_is_given_the_expected_parameters() {
        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: MockState?

        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        var receivedEvent: MockEvent?

        // Given: a transition that records its inputs
        let sut = Transitions {
            From(MockState.self) { state in
                On(MockEvent.self) { event in
                    receivedState = state
                    receivedEvent = event
                    return MockState(value: 1)
                }
            }
        }

        // When: executing the underlying reducer
        _ = sut.reducer(expectedState, expectedEvent)

        // Then: the reducer receives the expected inputs
        XCTAssertEqual(receivedState, expectedState)
        XCTAssertEqual(receivedEvent, expectedEvent)
    }

    func testReducer_merge_transitionsForStates_when_same_stateId() {
        let expectedState1 = MockState(value: Int.random(in: 1...1_000_000))
        let expectedState2 = MockState(value: Int.random(in: 1...1_000_000))

        // Given: a state machine declaring 2 distinct transitions for MockState
        let sut = Transitions {
            From(MockState.self) {
                On(MockEvent.self, transitionTo: expectedState1)
            }
            From(MockState.self) {
                On(AnotherMockEvent.self, transitionTo: expectedState2)
            }
        }

        // When: executing the reducer with the same MockState but 2 different Events
        // Then: both transitions are executed
        sut.assertThat(from: MockState(value: 1), on: MockEvent(value: 1), newStateIs: expectedState1)
        sut.assertThat(from: MockState(value: 1), on: AnotherMockEvent(), newStateIs: expectedState2)
    }

    func testDisable_dynamically_disable_the_transitions() {
        var isDisabled = true

        // Given: some transitions that is disabled when isDisabled is true
        let sut = Transitions {
            From(MockState.self) {
                On(MockEvent.self, transitionTo: AnotherMockState(value: 1))
            }

            From(AnotherMockState.self) {
                On(AnotherMockEvent.self, transitionTo: MockState(value: 1))
            }
        }
        .disable { isDisabled }

        // When: executing its associated reducer when isDisabled is true
        // Then: the state machine returns the input state
        sut.assertThatStateIsUnchanged(from: MockState(value: Int.random(in: 0...1_000_000)), on: MockEvent(value: 1))
        sut.assertThatStateIsUnchanged(from: AnotherMockState(value: Int.random(in: 0...1_000_000)), on: AnotherMockEvent())

        isDisabled = false

        // When: executing its associated reducer when isDisabled is false
        // Then: the state machine computes expected new states
        sut.assertThat(from: MockState(value: 1), on: MockEvent(value: 1), newStateIs: AnotherMockState(value: 1))
        sut.assertThat(from: AnotherMockState(value: 2), on: AnotherMockEvent(), newStateIs: MockState(value: 1))

        isDisabled = true

        // When: executing its associated reducer when isDisabled is true
        // Then: the state machine returns the input state
        sut.assertThatStateIsUnchanged(from: MockState(value: Int.random(in: 0...1_000_000)), on: MockEvent(value: 1))
        sut.assertThatStateIsUnchanged(from: AnotherMockState(value: Int.random(in: 0...1_000_000)), on: AnotherMockEvent())
    }
}

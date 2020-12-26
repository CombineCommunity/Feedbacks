//
//  TransitionTests.swift
//
//
//  Created by Thibault Wittemberg on 2020-12-24.
//

import Feedbacks
import XCTest

private struct MockState: State, Equatable { let value: Int }
private struct AnotherMockState: State, Equatable { let value: Int }
private struct WrongMockState: State {}

private struct MockEvent: Event {}
private struct AnotherMockEvent: Event {}
private struct WrongMockEvent: Event {}

final class TransitionTests: XCTestCase {
    func testInit_use_stateId_and_eventId_to_register_the_reducer() {
        var transitionIsCalled = false

        // Given: a transition for a state type and an event type
        let sut = Transition(from: MockState.self, on: MockEvent.self) { _, _ in
            transitionIsCalled = true
            return MockState(value: 2)
        }

        // When: retrieving the reducer matching the transition id
        let transitionId = TransitionId(stateId: MockState.id, eventId: MockEvent.id)
        let receivedReducer = sut.entries[transitionId]!

        // When: calling that reducer
        _ = receivedReducer(MockState(value: 1), MockEvent())

        // Then: the transition's reducer is called
        XCTAssertTrue(transitionIsCalled)
    }

    func testInit_make_a_reducer_that_accept_only_expected_stateType() {
        var transitionIsCalled = false

        // Given: a transition for a state type and an event type
        let sut = Transition(from: MockState.self, on: MockEvent.self) { _, _ in
            transitionIsCalled = true
            return MockState(value: 2)
        }

        // When: retrieving the reducer matching the transition id
        let transitionId = TransitionId(stateId: MockState.id, eventId: MockEvent.id)
        let receivedReducer = sut.entries[transitionId]!

        // When: calling that reducer with an unexpected state type
        _ = receivedReducer(WrongMockState(), MockEvent())

        // Then: the transition's reducer is not called
        XCTAssertFalse(transitionIsCalled)
    }

    func testInit_make_a_reducer_that_accept_only_expected_eventType() {
        var transitionIsCalled = false

        // Given: a transition for a state type and an event type
        let sut = Transition(from: MockState.self, on: MockEvent.self) { _, _ in
            transitionIsCalled = true
            return MockState(value: 2)
        }

        // When: retrieving the reducer matching the transition id
        let transitionId = TransitionId(stateId: MockState.id, eventId: MockEvent.id)
        let receivedReducer = sut.entries[transitionId]!

        // When: calling that reducer with an unexpected event type
        _ = receivedReducer(MockState(value: 1), WrongMockEvent())

        // Then: the transition's reducer is not called
        XCTAssertFalse(transitionIsCalled)
    }

    func testInit_make_a_reducer_returning_the_thenState() {
        let expectedState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: a transition for a state type and an event type, returning a known new state
        let sut = Transition(from: MockState.self, on: MockEvent.self, then: expectedState)

        // When: retrieving the reducer matching the transition id
        let transitionId = TransitionId(stateId: MockState.id, eventId: MockEvent.id)
        let receivedReducer = sut.entries[transitionId]!

        // When: calling that reducer
        let receivedState = receivedReducer(MockState(value: 1), MockEvent())

        // Then: the transition's reducer returns the expected state
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }
}

extension TransitionTests {
    func testEquality() {
        // Given: 3 transitions
        let transitionA = Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1))
        let transitionB = Transition(from: AnotherMockState.self, on: AnotherMockEvent.self, then: MockState(value: 2))
        let transitionC = Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 2))

        // When: comparing them for their equality
        // Then: A == C and A != B
        XCTAssertEqual(transitionA, transitionC)
        XCTAssertNotEqual(transitionA, transitionB)
    }
}

//
//  OnTests.swift
//  
//
//  Created by Thibault Wittemberg on 2021-02-21.
//

@testable import Feedbacks
import XCTest

private struct MockState: State, Equatable { let value: Int }
private struct AnotherMockState: State, Equatable { let value: Int }
private struct MockEvent: Event, Equatable { let value: Int }
private struct AnotherMockEvent: Event {}

final class OnTests: XCTestCase {
    func testTransitionForEvent_return_the_declared_state_when_called_with_an_event_of_the_declared_type() {
        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        var receivedEvent: MockEvent?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: an On that expect a MockEvent type and return an expected state
        let sut = On(MockEvent.self) { event in
            receivedEvent = event
            return expectedState
        }

        // When: calling the underlying transition with the expected MockEvent type
        let receivedState = sut.transitionForEvent(expectedEvent)

        // Then: the received event is the expected one
        XCTAssertEqual(receivedEvent, expectedEvent)

        // Then: the received state is the expected one
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }

    func testTransitionForEvent_return_the_declared_state_when_called_with_an_event_of_the_declared_type_without_parameter() {
        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: an On that expect a MockEvent type and return an expected state
        let sut = On(MockEvent.self) {
            return expectedState
        }

        // When: calling the underlying transition with the expected MockEvent type
        let receivedState = sut.transitionForEvent(expectedEvent)

        // Then: the received state is the expected one
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }

    func testTransitionForEvent_return_nil_when_called_with_an_event_not_of_the_declared_type_without_parameter() {
        let expectedEvent = AnotherMockEvent()

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: an On that expect a MockEvent type and return an expected state
        let sut = On(MockEvent.self) {
            return expectedState
        }

        // When: calling the underlying transition with an unexpected Event type
        let receivedState = sut.transitionForEvent(expectedEvent)

        // Then: the received state is nil
        XCTAssertNil(receivedState)
    }

    func testTransitionForEvent_return_the_declared_state_when_called_with_an_event_of_the_declared_type_with_transitionTo() {
        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        let expectedState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: an On that expect a MockEvent type and return an expected state
        let sut = On(MockEvent.self, transitionTo: expectedState)

        // When: calling the underlying transition with the expected MockEvent type
        let receivedState = sut.transitionForEvent(expectedEvent)

        // Then: the received state is the expected one
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }

    func testTransitionForEvent_return_nil_when_called_with_an_event_not_of_the_declared_type() {
        let expectedState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: an On that expect a MockEvent type and return an expected state
        let sut = On(MockEvent.self) { event in
            expectedState
        }

        // When: calling the underlying transition with an unexpected AnotherMockEvent type
        // Then: the call returns nil
        XCTAssertNil(sut.transitionForEvent(AnotherMockEvent()))
    }
    
    func testTransitionForEvent_return_nil_when_called_with_an_event_not_of_the_declared_type_with_transitionTo() {
        let expectedState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: an On that expect a MockEvent type and return an expected state
        let sut = On(MockEvent.self, transitionTo: expectedState)

        // When: calling the underlying transition with an unexpected AnotherMockEvent type
        // Then: the call returns nil
        XCTAssertNil(sut.transitionForEvent(AnotherMockEvent()))
    }

    func testTransitionForEvent_return_the_declared_state_when_called_with_AnyEvent() {
        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        var receivedEvent: Event?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: an On reacting to any event
        let sut = On(AnyEvent.self) { event in
            receivedEvent = event
            return expectedState
        }

        // When: calling the underlying transition with the expected MockEvent type
        let receivedState = sut.transitionForEvent(expectedEvent)

        // Then: the received event is the expected one
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        // Then: the received state is the expected one
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }

    func testTransitionForEvent_return_the_declared_state_when_called_with_AnyEvent_without_parameter() {
        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        let expectedState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: an On reacting to any event
        let sut = On(AnyEvent.self) {
            return expectedState
        }

        // When: calling the underlying transition with the expected MockEvent type
        let receivedState = sut.transitionForEvent(expectedEvent)

        // Then: the received state is the expected one
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }
    
    func testTransitionForEvent_return_the_declared_state_when_called_with_AnyEvent_with_transitionTo() {
        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        let expectedState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: an On reacting to any event
        let sut = On(AnyEvent.self, transitionTo: expectedState)

        // When: calling the underlying transition with the expected MockEvent type
        let receivedState = sut.transitionForEvent(expectedEvent)

        // Then: the received state is the expected one
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }

    func testDisable_do_not_execute_the_transition_when_is_disabled() {
        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var condition = true

        // Given: an On that is disabled depending on the "condition" value
        let sut = On(MockEvent.self) { event in
            expectedState
        }.disable {
            condition == true
        }

        // When: calling the underlying transition while disabled
        // Then: the call returns nil
        XCTAssertNil(sut.transitionForEvent(AnotherMockEvent()))

        condition = false

        // When: calling the underlying transition while not disabled
        let receivedState = sut.transitionForEvent(MockEvent(value: Int.random(in: 1...1_000_000)))

        // Then: the received state is the expected one
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }
}

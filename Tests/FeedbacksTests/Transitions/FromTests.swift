//
//  FromTests.swift
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

final class FromTests: XCTestCase {
    func testTransitionsForState_has_no_transitions_when_state_is_not_expectedType() {
        // Given: a From handling a MockState
        let sut = From(MockState.self) { _ in
            On(AnyEvent.self) { _ in
                return MockState(value: Int.random(in: 1...1_000_000))
            }
        }

        // When: giving the From an unexpected state type
        let receivedOns = sut.transitionsForState(AnotherMockState(value: 1))
        
        // Then: no transitions are computed
        XCTAssertEqual(sut.id, MockState.id)
        XCTAssertTrue(receivedOns.isEmpty)
    }
    
    func testTransitionsForState_has_no_transitions_when_state_is_not_expectedType_with_parameterLess_resultBuilder() {
        // Given: a From handling a MockState
        let sut = From(MockState.self) {
            On(AnyEvent.self) { _ in
                return MockState(value: Int.random(in: 1...1_000_000))
            }
        }

        // When: giving the From an unexpected state type
        let receivedOns = sut.transitionsForState(AnotherMockState(value: 1))
        
        // Then: no transitions are computed
        XCTAssertEqual(sut.id, MockState.id)
        XCTAssertTrue(receivedOns.isEmpty)
    }
    
    func testTransitionsForState_has_transitions_when_state_is_expectedType() {
        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: MockState?

        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        var receivedEvent: MockEvent?

        let expectedNewState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: a From handling a MockState
        let sut = From(MockState.self) { state in
            On(MockEvent.self) { event in
                receivedState = state
                receivedEvent = event
                return expectedNewState
            }
        }
        
        // When: giving the From an expected state type
        let receivedOns = sut.transitionsForState(expectedState)

        // Then: the From has 1 On transition with the expected behavior
        XCTAssertEqual(sut.id, MockState.id)
        XCTAssertEqual(receivedOns.count, 1)
        XCTAssertEqual(receivedOns.first!.id, MockEvent.id)
        XCTAssertEqual(receivedOns.first!.transitionForEvent(expectedEvent) as? MockState, expectedNewState)
        XCTAssertEqual(receivedState, expectedState)
        XCTAssertEqual(receivedEvent, expectedEvent)
    }
    
    func testTransitionsForState_has_transitions_when_state_is_expectedType_with_parameterLess_resultBuilder() {
        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        let expectedNewState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: a From handling a MockState
        let sut = From(MockState.self) {
            On(MockEvent.self) { _ in
                return expectedNewState
            }
        }
        
        // When: giving the From an expected state type
        let receivedOns = sut.transitionsForState(expectedState)

        // Then: the From has 1 On transition with the expected behavior
        XCTAssertEqual(sut.id, MockState.id)
        XCTAssertEqual(receivedOns.count, 1)
        XCTAssertEqual(receivedOns.first!.id, MockEvent.id)
        XCTAssertEqual(receivedOns.first!.transitionForEvent(expectedEvent) as? MockState, expectedNewState)
    }
    
    func testTransitionsForState_has_transitions_when_anyState() {
        let expectedState = AnotherMockState(value: Int.random(in: 1...1_000_000))
        var receivedState: State?

        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        var receivedEvent: MockEvent?

        let expectedNewState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: a From handling AnyState
        let sut = From(AnyState.self) { state in
            On(MockEvent.self) { event in
                receivedState = state
                receivedEvent = event
                return expectedNewState
            }
        }
        
        // When: giving the From whatever state type
        let receivedOns = sut.transitionsForState(expectedState)

        // Then: the From has 1 On transition with the expected behavior
        XCTAssertEqual(sut.id, AnyState.id)
        XCTAssertEqual(receivedOns.count, 1)
        XCTAssertEqual(receivedOns.first!.id, MockEvent.id)
        XCTAssertEqual(receivedOns.first!.transitionForEvent(expectedEvent) as? MockState, expectedNewState)
        XCTAssertEqual(receivedState as? AnotherMockState, expectedState)
        XCTAssertEqual(receivedEvent, expectedEvent)
    }
    
    func testTransitionsForState_has_transitions_when_anyState_with_parameterLess_resultBuilder() {
        let expectedState = AnotherMockState(value: Int.random(in: 1...1_000_000))
        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        let expectedNewState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: a From handling AnyState
        let sut = From(AnyState.self) {
            On(MockEvent.self) { event in
                return expectedNewState
            }
        }
        
        // When: giving the From whatever state type
        let receivedOns = sut.transitionsForState(expectedState)

        // Then: the From has 1 On transition with the expected behavior
        XCTAssertEqual(sut.id, AnyState.id)
        XCTAssertEqual(receivedOns.count, 1)
        XCTAssertEqual(receivedOns.first!.id, MockEvent.id)
        XCTAssertEqual(receivedOns.first!.transitionForEvent(expectedEvent) as? MockState, expectedNewState)
    }
    
    func testComputeTransitionsForEvents_return_empty_when_state_is_not_expectedType() {
        // Given: a From handling a MockState
        let sut = From(MockState.self) { state in
            On(AnyEvent.self) { event in
                return MockState(value: Int.random(in: 1...1_000_000))
            }
        }

        // When: giving the From an unexpected state type
        let receivedTransitionsForEvents = sut.computeTransitionsForEvents(for: AnotherMockState(value: 1))
        
        // Then: no transitions are computed
        XCTAssertTrue(receivedTransitionsForEvents.isEmpty)
    }
    
    func testComputeTransitionsForEvents_return_transitionsForEvents_when_state_is_expectedType() {
        let expectedNewState = MockState(value: Int.random(in: 1...1_000_000))

        // Given: a From handling a MockState
        let sut = From(MockState.self) { state in
            On(MockEvent.self) { event in
                return expectedNewState
            }
        }
        
        // When: giving the From an expected state type
        let computeTransitionsForEvents = sut.computeTransitionsForEvents(for: MockState(value: Int.random(in: 1...1_000_000)))

        // Then: the From has 1 On transition with the expected behavior
        XCTAssertEqual(computeTransitionsForEvents.count, 1)
        XCTAssertEqual(computeTransitionsForEvents.first!.key, MockEvent.id)
        XCTAssertEqual(computeTransitionsForEvents.first!.value(MockEvent(value: Int.random(in: 1...1_000_000))) as? MockState, expectedNewState)
    }

    func testComputeTransitionsForEvents_overwrite_transitionsForEvents_when_same_eventId() {
        // Given: 2 transitions from MockState/MockEvent
        let sut = From(MockState.self) {
            On(MockEvent.self, transitionTo: MockState(value: 1))
            On(MockEvent.self, transitionTo: MockState(value: 2))
        }

        // When: computing the transitions for events
        let transitionForEvents = sut.computeTransitionsForEvents(for: MockState(value: 1))

        // Then: only one transition is kept
        // Then: the last transition is kept
        XCTAssertEqual(transitionForEvents.count, 1)
        XCTAssertEqual(transitionForEvents.first!.key, MockEvent.id)
        XCTAssertEqual(transitionForEvents.first!.value(MockEvent(value: 1)) as? MockState, MockState(value: 2))
    }

    func testComputeTransitionsForEvents_merge_transitionsForStates_when_existing_transitions() {
        // Given: 1 `From` transition for MockState/MockEvent
        let sut = From(MockState.self) {
            On(MockEvent.self, transitionTo: MockState(value: 1))
        }

        // When: computing the transitions for events based on an existing set of transitions for the same state id
        let transitionForEvents = sut.computeTransitionsForEvents(for: MockState(value: 1)) { _ in [AnotherMockEvent.id: { _ in MockState(value: 2) }] }

        // Then: 2 transitions are computed for the MockState id
        XCTAssertEqual(transitionForEvents.count, 2)
        XCTAssertTrue(transitionForEvents.contains(where: { $0.key == MockEvent.id }))
        XCTAssertTrue(transitionForEvents.contains(where: { $0.key == AnotherMockEvent.id }))
        XCTAssertEqual(transitionForEvents[MockEvent.id]?(MockEvent(value: 1)) as? MockState, MockState(value: 1))
        XCTAssertEqual(transitionForEvents[AnotherMockEvent.id]?(AnotherMockEvent()) as? MockState, MockState(value: 2))
    }

    func testComputeTransitionsForEvents_merge_transitionsForStates_when_existing_transitions_with_overwrite_when_same_eventId() {
        // Given: 1 `From` transition for MockState/MockEvent
        let sut = From(MockState.self) {
            On(MockEvent.self, transitionTo: MockState(value: 1))
        }

        // When: computing the transitions for events based on an existing set of transitions for the same state id and the same event id
        let transitionForEvents = sut.computeTransitionsForEvents(for: MockState(value: 1)) { _ in [MockEvent.id: { _ in MockState(value: 2) }] }

        // Then: 1 transition is computed for the MockState id (the last one)
        XCTAssertEqual(transitionForEvents.count, 1)
        XCTAssertEqual(transitionForEvents[MockEvent.id]?(MockEvent(value: 1)) as? MockState, MockState(value: 2))
    }
    
    func testDisable_compute_new_state_only_when_not_disabled() {
        let expectedNewState = MockState(value: Int.random(in: 1...1_000_000))
        var condition = true

        // Given: a From disabled when condition is true
        let sut = From(MockState.self) { state in
            On(MockEvent.self) { event in
                return expectedNewState
            }
        }.disable {
            condition == true
        }
        
        // When: executing the declared transition
        let receivedNewStateWhenDisabled = sut.transitionsForState(MockState(value: 1)).first!.transitionForEvent(MockEvent(value: 1))
        
        // Then: the new state is nil
        XCTAssertNil(receivedNewStateWhenDisabled)
        
        condition = false
        
        // When: executing the declared transition with condition to false
        let receivedNewStateWhenEnabled = sut.transitionsForState(MockState(value: 1)).first!.transitionForEvent(MockEvent(value: 1))

        // Then: the new state is the expected one
        XCTAssertEqual(receivedNewStateWhenEnabled as? MockState, expectedNewState)
    }
}

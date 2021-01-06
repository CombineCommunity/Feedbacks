//
//  TransitionsTests.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-24.
//

import Feedbacks
import XCTest

private struct MockState: State, Equatable { let value: Int }
private struct AnotherMockState: State, Equatable { let value: Int }

private struct MockEvent: Event {}
private struct AnotherMockEvent: Event {}

final class TransitionsTests: XCTestCase {
    func testEntries_merge_entries_from_composing_transitions() {
        // Given: some transitions
        let transitionA = Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1))
        let transitionB = Transition(from: AnotherMockState.self, on: AnotherMockEvent.self, then: MockState(value: 2))
        
        let sut = Transitions {
            transitionA
            transitionB
        }
        
        // When: getting the transitions entries
        let expectedEntries = transitionA.entries.merging(transitionB.entries, uniquingKeysWith: { $1 })
        let receivedEntries = sut.entries
        
        // Then: they are equal to the merging of its composing transitions
        XCTAssertEqual(receivedEntries.keys, expectedEntries.keys)
    }
    
    func testEntries_merge_entries_from_composing_transitions_using_the_second_transition_when_ids_are_equal() {
        // Given: 2 transitions having the same ids
        let transitionA = Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1))
        let transitionB = Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1701))
        
        let sut = Transitions {
            transitionA
            transitionB
        }
        
        // When: getting the transitions entries
        let receivedEntries = sut.entries
        
        // Then: the entries have only one entry, which is the last declared transition (transitionB)
        XCTAssertEqual(receivedEntries.count, 1)
        
        let transitionBId = TransitionId(stateId: MockState.id, eventId: MockEvent.id)
        let receivedReducer = receivedEntries[transitionBId]!
        let receivedState = receivedReducer(MockState(value: 1), MockEvent())
        
        XCTAssertEqual(receivedState as? MockState, MockState(value: 1701))
    }
    
    func testReducer_handle_the_combination_of_registered_and_not_registered_states_and_events() {
        // Given: some transitions that handles registered states and events and also any states and any events
        
        let mockTransitions = Transitions {
            Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1))
            Transition(from: MockState.self, on: AnyEvent.self, then: MockState(value: 2))
        }
        
        let anyTransitions = Transitions {
            Transition(from: AnyState.self, on: MockEvent.self, then: MockState(value: 3))
            Transition(from: AnyState.self, on: AnyEvent.self, then: MockState(value: 4))
        }
        
        let sut = Transitions {
            mockTransitions
            anyTransitions
        }
        
        // When: getting its reducer and giving it all the combinations are registers / not registered states and events
        let receivedReducer = sut.reducer
        
        let receivedStateWhenStateAndEventAreExplicitlyRegistered = receivedReducer(MockState(value: 1), MockEvent())
        let receivedStateWhenStateIsExplicitlyRegisteredAndEventIsNot = receivedReducer(MockState(value: 1), AnotherMockEvent())
        let receivedStateWhenStateIsNotExplicitlyRegisteredAndEventIs = receivedReducer(AnotherMockState(value: 2), MockEvent())
        let receivedStateWhenStateAndEventAreNotExplicitlyRegistered = receivedReducer(AnotherMockState(value: 2), AnotherMockEvent())
        
        // Then: the reducer handles all the cases with the expected priority
        XCTAssertEqual(receivedStateWhenStateAndEventAreExplicitlyRegistered as? MockState, MockState(value: 1))
        XCTAssertEqual(receivedStateWhenStateIsExplicitlyRegisteredAndEventIsNot as? MockState, MockState(value: 2))
        XCTAssertEqual(receivedStateWhenStateIsNotExplicitlyRegisteredAndEventIs as? MockState, MockState(value: 3))
        XCTAssertEqual(receivedStateWhenStateAndEventAreNotExplicitlyRegistered as? MockState, MockState(value: 4))
    }
    
    func testReducer_handle_the_combination_of_registered_and_not_registered_states_and_events2() {
        // Given: some transitions that only handles registered states and events (no any states and any events)
        let sut = Transitions {
            Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1))
        }
        
        // When: getting its reducer and giving it unregistered state and event
        let receivedReducer = sut.reducer
        
        let expectedState = AnotherMockState(value: 1701)
        
        let receivedStateWhenStateAndEventAreNotExplicitlyRegistered = receivedReducer(expectedState, AnotherMockEvent())
        
        // Then: the reducer returns the input state as a new state
        XCTAssertEqual(receivedStateWhenStateAndEventAreNotExplicitlyRegistered as? AnotherMockState, expectedState)
    }
    
    func testDisable_dynamically_disable_the_transitions() {
        var isDisabled = true
        
        // Given: some transitions that is disabled when isDisabled is true
        let sut = Transitions {
            Transition(from: MockState.self, on: MockEvent.self, then: AnotherMockState(value: 1))
            Transition(from: AnotherMockState.self, on: AnotherMockEvent.self, then: MockState(value: 1))
        }
        .disable { isDisabled }
        
        let reducer = sut.reducer
        
        // When: executing its associated reducer when isDisabled is true
        let inputMockState1 = MockState(value: Int.random(in: 0...1_000_000))
        let newMockState1 = reducer(inputMockState1, MockEvent())
        // Then: the newMockState1 is the one from the input
        XCTAssertEqual(newMockState1 as? MockState, inputMockState1)
        
        let inputAnotherMockState1 = AnotherMockState(value: Int.random(in: 0...1_000_000))
        let newAnotherMockState1 = reducer(inputAnotherMockState1, AnotherMockEvent())
        // Then: the newAnotherMockState1 is the one from the input
        XCTAssertEqual(newAnotherMockState1 as? AnotherMockState, inputAnotherMockState1)
        
        isDisabled = false
        
        // When: executing its associated reducer when isDisabled is false
        let newMockState2 = reducer(MockState(value: 1), MockEvent())
        // Then: the newMockState2 is the one declared in the transition
        XCTAssertEqual(newMockState2 as? AnotherMockState, AnotherMockState(value: 1))
        
        let newAnotherMockState2 = reducer(AnotherMockState(value: 2), AnotherMockEvent())
        // Then: the newAnotherMockState2 is the one from the input
        XCTAssertEqual(newAnotherMockState2 as? MockState, MockState(value: 1))
        
        isDisabled = true
        
        // When: executing its associated reducer when isDisabled is true
        let inputMockState3 = MockState(value: Int.random(in: 0...1_000_000))
        let newMockState3 = reducer(inputMockState3, MockEvent())
        // Then: the newMockState3 is the one from the input
        XCTAssertEqual(newMockState3 as? MockState, inputMockState3)
        
        let inputAnotherMockState3 = AnotherMockState(value: Int.random(in: 0...1_000_000))
        let newAnotherMockState3 = reducer(inputAnotherMockState3, AnotherMockEvent())
        // Then: the newAnotherMockState3 is the one from the input
        XCTAssertEqual(newAnotherMockState3 as? AnotherMockState, inputAnotherMockState3)
    }
}

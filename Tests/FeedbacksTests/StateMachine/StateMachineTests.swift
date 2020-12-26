//
//  StateMachineTests.swift
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

final class StateMachineTests: XCTestCase {
    func testEntries_merge_entries_from_composing_transitions() {
        // Given: a StateMachine with some transitions
        struct MockStateMachine: StateMachineDefinition {
            let transitionA = Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1))
            let transitionB = Transition(from: AnotherMockState.self, on: AnotherMockEvent.self, then: MockState(value: 2))

            var transitions: [Transitions] {
                transitionA
                transitionB
            }
        }

        let sut = MockStateMachine()

        // When: getting the state machine's entries
        let expectedEntries = sut.transitionA.entries.merging(sut.transitionB.entries, uniquingKeysWith: { $1 })
        let receivedEntries = sut.entries

        // Then: they are equal to the merging of its composing transitions
        XCTAssertEqual(receivedEntries.keys, expectedEntries.keys)
    }

    func testEntries_merge_entries_from_composing_transitions_using_the_second_transition_when_ids_are_equal() {
        // Given: a StateMachine with 2 transitions having the same ids
        let transitionA = Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1))
        let transitionB = Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1701))

        let sut = StateMachine {
            transitionA
            transitionB
        }

        // When: getting the state machine's entries
        let receivedEntries = sut.entries

        // Then: the entries have only one entry, which is the last declared transition (transitionB)
        XCTAssertEqual(receivedEntries.count, 1)

        let transitionBId = TransitionId(stateId: MockState.id, eventId: MockEvent.id)
        let receivedReducer = receivedEntries[transitionBId]!
        let receivedState = receivedReducer(MockState(value: 1), MockEvent())

        XCTAssertEqual(receivedState as? MockState, MockState(value: 1701))
    }

    func testReducer_handle_the_combination_of_registered_and_not_registered_states_and_events() {
        // Given: a state machine that handles registered states and events and also any states and any events

        let mockStateMachine = StateMachine {
            Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1))
            Transition(from: MockState.self, on: AnyEvent.self, then: MockState(value: 2))
        }

        let anyStateMachine = StateMachine {
            Transition(from: AnyState.self, on: MockEvent.self, then: MockState(value: 3))
            Transition(from: AnyState.self, on: AnyEvent.self, then: MockState(value: 4))
        }

        let sut = StateMachine {
            mockStateMachine
            anyStateMachine
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
        // Given: a state machine that only handles registered states and events (no any states and any events)
        let sut = StateMachine {
            Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1))
        }

        // When: getting its reducer and giving it unregistered state and event
        let receivedReducer = sut.reducer

        let expectedState = AnotherMockState(value: 1701)

        let receivedStateWhenStateAndEventAreNotExplicitlyRegistered = receivedReducer(expectedState, AnotherMockEvent())

        // Then: the reducer returns the input state as a new state
        XCTAssertEqual(receivedStateWhenStateAndEventAreNotExplicitlyRegistered as? AnotherMockState, expectedState)
    }
}

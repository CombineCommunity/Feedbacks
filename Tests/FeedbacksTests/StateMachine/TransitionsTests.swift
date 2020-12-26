//
//  TransitionsTests.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-26.
//

import Feedbacks
import XCTest

private struct MockState: State, Equatable { let value: Int }
private struct AnotherMockState: State, Equatable { let value: Int }

private struct MockEvent: Event {}
private struct AnotherMockEvent: Event {}

final class TransitionsTests: XCTestCase {
    func testBuildBlock_build_array_of_transitions_with_variadicParameterOfTransitions() {
        // Given: 2 transitions
        let transitionA = Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1))
        let transitionB = Transition(from: AnotherMockState.self, on: AnotherMockEvent.self, then: MockState(value: 2))

        // When: making an array of transitions thanks to the ResultBuilder
        let receivedTransitions = TransitionsBuilder.buildBlock(transitionA, transitionB)

        // Then: the array of transitions is composed of the input transitions
        let receivedTransitionIds = receivedTransitions.flatMap { $0.entries.map { $0.key } }
        let expectedTransitionsIds = ([transitionA, transitionB] as [Transitions]).flatMap { $0.entries.map { $0.key } }
        XCTAssertEqual(receivedTransitionIds, expectedTransitionsIds)
    }
}

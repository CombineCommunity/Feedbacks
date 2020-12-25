//
//  InitialStateTests.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-29.
//

@testable import Feedbacks
import XCTest

private struct MockState: State, Equatable { let value: Int }

final class InitialStateTests: XCTestCase {
    func testInit_store_the_input_value() {
        let expectedValue = Int.random(in: 1...1_000_000)

        // Given: an initial state with a randomized state
        let sut = InitialState {
            MockState(value: expectedValue)
        }

        // When: getting the initial state's value
        // Then: it is equal to the state given as the init input
        XCTAssertEqual((sut.value as? MockState)!.value, expectedValue)
    }
}

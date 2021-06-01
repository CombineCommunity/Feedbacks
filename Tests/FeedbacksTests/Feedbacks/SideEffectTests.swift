//
//  SideEffectTests.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-29.
//

import Combine
import Feedbacks
import XCTest

private struct MockState: State, Equatable { let value: Int }

final class SideEffectTests: XCTestCase {}

// MARK: tests for SideEffect.make() with an AnyPublisher<State, Never>
extension SideEffectTests {
    func testMake_give_expected_parameters_when_oneArg_and_stateAsPublisher() {
        let expectedArg = Int.random(in: 1...1_000_000)
        var receivedArg: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedPublisher: AnyPublisher<State, Never>?

        // Given: a side effect that expects an arg and a state publisher
        let sut = SideEffect.make({ (arg: Int, publisher: AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> in
            receivedArg = arg
            receivedPublisher = publisher
            return Empty().eraseToAnyPublisher()
        }, arg: expectedArg)

        // When: executing the side effect
        _ = sut(Just<State>(expectedState).eraseToAnyPublisher())

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg, expectedArg)
        _ = receivedPublisher?.sink(receiveValue: { XCTAssertEqual($0 as? MockState, expectedState) })
    }

    func testMake_give_expected_parameters_when_twoArgs_and_stateAsPublisher() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedPublisher: AnyPublisher<State, Never>?

        // Given: a side effect that expects 2 args and a state publisher
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, publisher: AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedPublisher = publisher
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2)

        // When: executing the side effect
        _ = sut(Just<State>(expectedState).eraseToAnyPublisher())

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        _ = receivedPublisher?.sink(receiveValue: { XCTAssertEqual($0 as? MockState, expectedState) })
    }

    func testMake_give_expected_parameters_when_threeArgs_and_stateAsPublisher() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        let expectedArg3 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?
        var receivedArg3: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedPublisher: AnyPublisher<State, Never>?

        // Given: a side effect that expects 3 args and a state publisher
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, arg3: Int, publisher: AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedArg3 = arg3
            receivedPublisher = publisher
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2, arg3: expectedArg3)

        // When: executing the side effect
        _ = sut(Just<State>(expectedState).eraseToAnyPublisher())

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        XCTAssertEqual(receivedArg3, expectedArg3)
        _ = receivedPublisher?.sink(receiveValue: { XCTAssertEqual($0 as? MockState, expectedState) })
    }

    func testMake_give_expected_parameters_when_fourArgs_and_stateAsPublisher() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        let expectedArg3 = Int.random(in: 1...1_000_000)
        let expectedArg4 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?
        var receivedArg3: Int?
        var receivedArg4: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedPublisher: AnyPublisher<State, Never>?

        // Given: a side effect that expects 4 args and a state publisher
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, arg3: Int, arg4: Int, publisher: AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedArg3 = arg3
            receivedArg4 = arg4
            receivedPublisher = publisher
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2, arg3: expectedArg3, arg4: expectedArg4)

        // When: executing the side effect
        _ = sut(Just<State>(expectedState).eraseToAnyPublisher())

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        XCTAssertEqual(receivedArg3, expectedArg3)
        XCTAssertEqual(receivedArg4, expectedArg4)
        _ = receivedPublisher?.sink(receiveValue: { XCTAssertEqual($0 as? MockState, expectedState) })
    }

    func testMake_give_expected_parameters_when_fiveArgs_and_stateAsPublisher() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        let expectedArg3 = Int.random(in: 1...1_000_000)
        let expectedArg4 = Int.random(in: 1...1_000_000)
        let expectedArg5 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?
        var receivedArg3: Int?
        var receivedArg4: Int?
        var receivedArg5: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedPublisher: AnyPublisher<State, Never>?

        // Given: a side effect that expects 5 args and a state publisher
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, arg3: Int, arg4: Int, arg5: Int, publisher: AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedArg3 = arg3
            receivedArg4 = arg4
            receivedArg5 = arg5
            receivedPublisher = publisher
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2, arg3: expectedArg3, arg4: expectedArg4, arg5: expectedArg5)

        // When: executing the side effect
        _ = sut(Just<State>(expectedState).eraseToAnyPublisher())

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        XCTAssertEqual(receivedArg3, expectedArg3)
        XCTAssertEqual(receivedArg4, expectedArg4)
        XCTAssertEqual(receivedArg5, expectedArg5)
        _ = receivedPublisher?.sink(receiveValue: { XCTAssertEqual($0 as? MockState, expectedState) })
    }
}

// MARK: tests for SideEffect.make() with a State
extension SideEffectTests {
    func testMake_give_expected_parameters_when_oneArg_and_stateAsState() {
        let expectedArg = Int.random(in: 1...1_000_000)
        var receivedArg: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: State?

        // Given: a side effect that expects an arg and a state as State
        let sut = SideEffect.make({ (arg: Int, state: State) -> AnyPublisher<Event, Never> in
            receivedArg = arg
            receivedState = state
            return Empty().eraseToAnyPublisher()
        }, arg: expectedArg)

        // When: executing the side effect
        _ = sut(expectedState)

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg, expectedArg)
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }

    func testMake_give_expected_parameters_when_twoArgs_and_stateAsState() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: State?

        // Given: a side effect that expects 2 args and a state as State
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, state: State) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedState = state
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2)

        // When: executing the side effect
        _ = sut(expectedState)

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }

    func testMake_give_expected_parameters_when_threeArgs_and_stateAsState() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        let expectedArg3 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?
        var receivedArg3: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: State?

        // Given: a side effect that expects 3 args and a state as State
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, arg3: Int, state: State) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedArg3 = arg3
            receivedState = state
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2, arg3: expectedArg3)

        // When: executing the side effect
        _ = sut(expectedState)

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        XCTAssertEqual(receivedArg3, expectedArg3)
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }

    func testMake_give_expected_parameters_when_fourArgs_and_stateAsState() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        let expectedArg3 = Int.random(in: 1...1_000_000)
        let expectedArg4 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?
        var receivedArg3: Int?
        var receivedArg4: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: State?

        // Given: a side effect that expects 4 args and a state as State
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, arg3: Int, arg4: Int, state: State) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedArg3 = arg3
            receivedArg4 = arg4
            receivedState = state
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2, arg3: expectedArg3, arg4: expectedArg4)

        // When: executing the side effect
        _ = sut(expectedState)

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        XCTAssertEqual(receivedArg3, expectedArg3)
        XCTAssertEqual(receivedArg4, expectedArg4)
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }

    func testMake_give_expected_parameters_when_fiveArgs_and_stateAsState() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        let expectedArg3 = Int.random(in: 1...1_000_000)
        let expectedArg4 = Int.random(in: 1...1_000_000)
        let expectedArg5 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?
        var receivedArg3: Int?
        var receivedArg4: Int?
        var receivedArg5: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: State?

        // Given: a side effect that expects 5 args and a state as State
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, arg3: Int, arg4: Int, arg5: Int, state: State) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedArg3 = arg3
            receivedArg4 = arg4
            receivedArg5 = arg5
            receivedState = state
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2, arg3: expectedArg3, arg4: expectedArg4, arg5: expectedArg5)

        // When: executing the side effect
        _ = sut(expectedState)

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        XCTAssertEqual(receivedArg3, expectedArg3)
        XCTAssertEqual(receivedArg4, expectedArg4)
        XCTAssertEqual(receivedArg5, expectedArg5)
        XCTAssertEqual(receivedState as? MockState, expectedState)
    }
}

// MARK: tests for SideEffect.make() with a StateType
extension SideEffectTests {
    func testMake_give_expected_parameters_when_oneArg_and_stateAsStateType() {
        let expectedArg = Int.random(in: 1...1_000_000)
        var receivedArg: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: MockState?

        // Given: a side effect that expects an arg and a state as StateType
        let sut = SideEffect.make({ (arg: Int, state: MockState) -> AnyPublisher<Event, Never> in
            receivedArg = arg
            receivedState = state
            return Empty().eraseToAnyPublisher()
        }, arg: expectedArg)

        // When: executing the side effect
        _ = sut(expectedState)

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg, expectedArg)
        XCTAssertEqual(receivedState, expectedState)
    }

    func testMake_give_expected_parameters_when_twoArgs_and_stateAsStateType() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: MockState?

        // Given: a side effect that expects 2 args and a state as StateType
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, state: MockState) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedState = state
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2)

        // When: executing the side effect
        _ = sut(expectedState)

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        XCTAssertEqual(receivedState, expectedState)
    }

    func testMake_give_expected_parameters_when_threeArgs_and_stateAsStateType() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        let expectedArg3 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?
        var receivedArg3: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: MockState?

        // Given: a side effect that expects 3 args and a state as StateType
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, arg3: Int, state: MockState) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedArg3 = arg3
            receivedState = state
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2, arg3: expectedArg3)

        // When: executing the side effect
        _ = sut(expectedState)

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        XCTAssertEqual(receivedArg3, expectedArg3)
        XCTAssertEqual(receivedState, expectedState)
    }

    func testMake_give_expected_parameters_when_fourArgs_and_stateAsStateType() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        let expectedArg3 = Int.random(in: 1...1_000_000)
        let expectedArg4 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?
        var receivedArg3: Int?
        var receivedArg4: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: MockState?

        // Given: a side effect that expects 4 args and a state as StateType
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, arg3: Int, arg4: Int, state: MockState) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedArg3 = arg3
            receivedArg4 = arg4
            receivedState = state
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2, arg3: expectedArg3, arg4: expectedArg4)

        // When: executing the side effect
        _ = sut(expectedState)

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        XCTAssertEqual(receivedArg3, expectedArg3)
        XCTAssertEqual(receivedArg4, expectedArg4)
        XCTAssertEqual(receivedState, expectedState)
    }

    func testMake_give_expected_parameters_when_fiveArgs_and_stateAsStateType() {
        let expectedArg1 = Int.random(in: 1...1_000_000)
        let expectedArg2 = Int.random(in: 1...1_000_000)
        let expectedArg3 = Int.random(in: 1...1_000_000)
        let expectedArg4 = Int.random(in: 1...1_000_000)
        let expectedArg5 = Int.random(in: 1...1_000_000)
        var receivedArg1: Int?
        var receivedArg2: Int?
        var receivedArg3: Int?
        var receivedArg4: Int?
        var receivedArg5: Int?

        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        var receivedState: MockState?

        // Given: a side effect that expects 5 args and a state as StateType
        let sut = SideEffect.make({ (arg1: Int, arg2: Int, arg3: Int, arg4: Int, arg5: Int, state: MockState) -> AnyPublisher<Event, Never> in
            receivedArg1 = arg1
            receivedArg2 = arg2
            receivedArg3 = arg3
            receivedArg4 = arg4
            receivedArg5 = arg5
            receivedState = state
            return Empty().eraseToAnyPublisher()
        }, arg1: expectedArg1, arg2: expectedArg2, arg3: expectedArg3, arg4: expectedArg4, arg5: expectedArg5)

        // When: executing the side effect
        _ = sut(expectedState)

        // Then: the parameters given to SideEffect.make are given back to the side effect
        XCTAssertEqual(receivedArg1, expectedArg1)
        XCTAssertEqual(receivedArg2, expectedArg2)
        XCTAssertEqual(receivedArg3, expectedArg3)
        XCTAssertEqual(receivedArg4, expectedArg4)
        XCTAssertEqual(receivedArg5, expectedArg5)
        XCTAssertEqual(receivedState, expectedState)
    }
}

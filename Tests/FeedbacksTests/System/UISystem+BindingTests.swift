//
//  UISystem+BindingTests.swift
//  
//
//  Created by Thibault Wittemberg on 2021-01-03.
//

#if canImport(SwiftUI)
import Combine
import Feedbacks
import XCTest

private struct MockState: State, Equatable { let value: Int }
private struct MockViewState: ViewState {
    let value: Int
    
    static var undefined: MockViewState {
        MockViewState(value: -1)
    }
}
private struct MockEvent: Event, Equatable { let value: Int }

final class UISystem_BindingTests: XCTestCase {
    func testBinding_get_rawState_and_emit_event_when_defined_by_stateClosure_and_eventClosure() {
        let exp = expectation(description: "Binding")
        let expectedEvent = MockEvent(value: Int.random(in: 0...1_000_000))
        let expectedRawState = MockState(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?

        // Given: a UISystem for a RawState
        let sut = UISystem {
            InitialState {
                expectedRawState
            }

            Feedbacks {}
                .onEventEmitted { receivedEvent = $0 }

            Transitions {}
        }
        .execute(on: DispatchQueue.immediateScheduler)

        // When: running the system and waiting for the first not undefined view state
        let sutCancellable = sut.stream.sink { _ in }
        let stateCancellable = sut.$state.output(in: 0...1).sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })

        waitForExpectations(timeout: 0.5)

        // When: getting a binding from the RawState .value property, emitting a MockEvent when mutated
        let binding = sut.binding { rawState -> Int in
            (rawState.state as! MockState).value
        } emit: { value -> Event in
            MockEvent(value: value)
        }

        // Then: the binding's value is the expected one
        XCTAssertEqual(binding.wrappedValue, expectedRawState.value)

        // When: mutating the binding's value
        binding.wrappedValue = expectedEvent.value

        // Then: the expected event is propagated to the system
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        stateCancellable.cancel()
        sutCancellable.cancel()
    }

    func testBinding_get_rawState_and_emit_event_when_defined_by_stateClosure_and_directEvent() {
        let exp = expectation(description: "Binding")
        let expectedEvent = MockEvent(value: Int.random(in: 0...1_000_000))
        let expectedRawState = MockState(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?

        // Given: a UISystem for a RawState
        let sut = UISystem {
            InitialState {
                expectedRawState
            }

            Feedbacks {}
                .onEventEmitted { receivedEvent = $0 }

            Transitions {}
        }
        .execute(on: DispatchQueue.immediateScheduler)

        // When: running the system and waiting for the first not undefined view state
        let sutCancellable = sut.stream.sink { _ in }
        let stateCancellable = sut.$state.output(in: 0...1).sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })

        waitForExpectations(timeout: 0.5)

        // When: getting a binding from the RawState .value property, emitting a MockEvent when mutated
        let binding = sut.binding(
            get: { rawState -> Int in
                (rawState.state as! MockState).value
            },
            emit: expectedEvent)

        // Then: the binding's value is the expected one
        XCTAssertEqual(binding.wrappedValue, expectedRawState.value)

        // When: mutating the binding's value
        binding.wrappedValue = expectedEvent.value

        // Then: the expected event is propagated to the system
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        stateCancellable.cancel()
        sutCancellable.cancel()
    }

    func testBinding_get_rawState_and_emit_no_event_when_defined_only_by_stateClosure() {
        let exp = expectation(description: "Binding")
        let expectedRawState = MockState(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?

        // Given: a UISystem for a ViewState
        let sut = UISystem {
            InitialState {
                expectedRawState
            }

            Feedbacks {}
                .onEventEmitted { receivedEvent = $0 }

            Transitions {}
        }
        .execute(on: DispatchQueue.immediateScheduler)

        // When: running the system and waiting for the first not undefined view state
        let sutCancellable = sut.stream.sink { _ in }
        let stateCancellable = sut.$state.output(in: 0...1).sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })

        waitForExpectations(timeout: 0.5)

        // When: getting a binding from the RawState .value property, emitting no event when mutated
        let binding = sut.binding { rawState -> Int in (rawState.state as! MockState).value }

        // Then: the binding's value is the expected one
        XCTAssertEqual(binding.wrappedValue, expectedRawState.value)

        // When: mutating the binding's value
        binding.wrappedValue = 1

        // Then: no event is propagated to the system
        XCTAssertNil(receivedEvent)

        stateCancellable.cancel()
        sutCancellable.cancel()
    }

    func testBinding_get_viewState_and_emit_event_when_defined_by_viewStateKeypath_and_eventClosure() {
        let exp = expectation(description: "Binding")
        let expectedEvent = MockEvent(value: Int.random(in: 0...1_000_000))
        let expectedViewState = MockViewState(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?

        // Given: a UISystem for a ViewState
        let sut = UISystem(
            viewStateFactory: { _ -> MockViewState in
                return expectedViewState
            },
            on: DispatchQueue.immediateScheduler) {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }

            Feedbacks {}
                .onEventEmitted { receivedEvent = $0 }

            Transitions {}
        }
        .execute(on: DispatchQueue.immediateScheduler)

        // When: running the system and waiting for the first not undefined view state
        let sutCancellable = sut.stream.sink { _ in }
        let stateCancellable = sut.$state.output(in: 0...1).sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })
        
        waitForExpectations(timeout: 0.5)
        
        // When: getting a binding on the \.value property of the view state, emitting a MockEvent when mutated
        let binding = sut.binding(keyPath: \.value) { value -> Event in
            MockEvent(value: value)
        }
        
        // Then: the binding's value is the expected one
        XCTAssertEqual(binding.wrappedValue, expectedViewState.value)

        // When: mutating the binding's value
        binding.wrappedValue = expectedEvent.value

        // Then: the expected event is propagated to the system
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        stateCancellable.cancel()
        sutCancellable.cancel()
    }

    func testBinding_get_viewState_and_emit_event_when_defined_by_viewStateKeypath_and_directEvent() {
        let exp = expectation(description: "Binding")
        let expectedEvent = MockEvent(value: Int.random(in: 0...1_000_000))
        let expectedViewState = MockViewState(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?

        // Given: a UISystem for a ViewState
        let sut = UISystem(
            viewStateFactory: { _ -> MockViewState in
                return expectedViewState
            },
            on: DispatchQueue.immediateScheduler) {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }

            Feedbacks {}
                .onEventEmitted { receivedEvent = $0 }

            Transitions {}
        }
        .execute(on: DispatchQueue.immediateScheduler)

        // When: running the system and waiting for the first not undefined view state
        let sutCancellable = sut.stream.sink { _ in }
        let stateCancellable = sut.$state.output(in: 0...1).sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })
        
        waitForExpectations(timeout: 0.5)
        
        // When: getting a binding on the \.value property of the view state, emitting a MockEvent when mutated
        let binding = sut.binding(keyPath: \.value, emit: expectedEvent)
        
        // Then: the binding's value is the expected one
        XCTAssertEqual(binding.wrappedValue, expectedViewState.value)

        // When: mutating the binding's value
        binding.wrappedValue = expectedEvent.value

        // Then: the expected event is propagated to the system
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        stateCancellable.cancel()
        sutCancellable.cancel()
    }
    
    func testBinding_get_viewState_and_emit_no_event_when_defined_only_by_viewStateKeypath() {
        let exp = expectation(description: "Binding")
        let expectedViewState = MockViewState(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?

        // Given: a UISystem for a ViewState
        let sut = UISystem(
            viewStateFactory: { _ -> MockViewState in
                return expectedViewState
            },
            on: DispatchQueue.immediateScheduler) {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }

            Feedbacks {}
                .onEventEmitted { receivedEvent = $0 }

            Transitions {}
        }
        .execute(on: DispatchQueue.immediateScheduler)

        // When: running the system and waiting for the first not undefined view state
        let sutCancellable = sut.stream.sink { _ in }
        let stateCancellable = sut.$state.output(in: 0...1).sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })
        
        waitForExpectations(timeout: 0.5)
        
        // When: getting a binding on the \.value property of the view state, emitting no event when mutated
        let binding = sut.binding(keyPath: \.value)
        
        // Then: the binding's value is the expected one
        XCTAssertEqual(binding.wrappedValue, expectedViewState.value)

        // When: mutating the binding's value
        binding.wrappedValue = 1

        // Then: no event is propagated to the system
        XCTAssertNil(receivedEvent)

        stateCancellable.cancel()
        sutCancellable.cancel()
    }
}
#endif

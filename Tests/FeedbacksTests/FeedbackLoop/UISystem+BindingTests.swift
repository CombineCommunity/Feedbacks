//
//  UISystem+BindingTests.swift
//  
//
//  Created by Thibault Wittemberg on 2021-01-03.
//

#if canImport(SwiftUI)
//import SwiftUI
import Combine
import Feedbacks
import XCTest

private struct MockState: State, Equatable { let value: Int }
private struct MockViewState: State, Equatable, CanBeUndefined {
    let value: Int
    
    static var undefined: MockViewState {
        MockViewState(value: -1)
    }
}
private struct MockEvent: Event, Equatable { let value: Int }

final class UISystem_BindingTests: XCTestCase {
    func testBinding_get_viewState_emit_event_when_closure() {
        let exp = expectation(description: "Binding")
        let expectedEvent = MockEvent(value: Int.random(in: 0...1_000_000))
        let expectedViewState = MockViewState(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?

        // Given: a UISystem
        let sut = UISystem(viewStateFactory: { systemState -> MockViewState in
            return expectedViewState
        }) {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }

            Feedbacks {}
                .onEventEmitted { receivedEvent = $0 }

            Transitions {}
        }
        .execute(on: DispatchQueue.immediateScheduler)
        .executeViewStateFactory(on: DispatchQueue.immediateScheduler)

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
    
    func testBinding_get_viewState_emit_event() {
        let exp = expectation(description: "Binding")
        let expectedEvent = MockEvent(value: Int.random(in: 0...1_000_000))
        let expectedViewState = MockViewState(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?

        // Given: a UISystem
        let sut = UISystem(viewStateFactory: { systemState -> MockViewState in
            return expectedViewState
        }) {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }

            Feedbacks {}
                .onEventEmitted { receivedEvent = $0 }

            Transitions {}
        }
        .execute(on: DispatchQueue.immediateScheduler)
        .executeViewStateFactory(on: DispatchQueue.immediateScheduler)

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
    
    func testBinding_get_viewState_emit_no_event() {
        let exp = expectation(description: "Binding")
        let expectedViewState = MockViewState(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?

        // Given: a UISystem
        let sut = UISystem(viewStateFactory: { systemState -> MockViewState in
            return expectedViewState
        }) {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }

            Feedbacks {}
                .onEventEmitted { receivedEvent = $0 }

            Transitions {}
        }
        .execute(on: DispatchQueue.immediateScheduler)
        .executeViewStateFactory(on: DispatchQueue.immediateScheduler)

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

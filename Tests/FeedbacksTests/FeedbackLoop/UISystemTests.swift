//
//  UISystemTests.swift
//  
//
//  Created by Thibault Wittemberg on 2021-01-01.
//

import Combine
@testable import Feedbacks
import XCTest

private struct MockState: State, Equatable { let value: Int }
private struct MockViewState: State, Equatable, CanBeUndefined {
    let value: Int
    
    static var undefined: MockViewState {
        MockViewState(value: -1)
    }
}
private struct MockEvent: Event, Equatable { let value: Int }

final class UISystemTests: XCTestCase {
    func testInit_set_viewState_to_undefined_and_then_to_initialState() {
        let expectedViewState = MockViewState.undefined
        
        // Given: a UISystem with an initial state
        // When: initializing the UISystem
        let sut = UISystem(viewStateFactory: { systemState -> MockViewState in
            return MockViewState(value: Int.random(in: 0...1_000_000))
        },
        initialState: InitialState { MockState(value: Int.random(in: 0...1_000_000)) },
        feedbacks: Feedbacks {},
        stateMachine: StateMachine{},
        systemScheduler: DispatchQueue.immediateScheduler,
        viewStateScheduler: DispatchQueue.immediateScheduler)
        
        // Then: the UISystem's view state is set to undefined
        XCTAssertEqual(sut.state, expectedViewState)
    }
    
    func testInit_install_a_viewStateFactory_that_is_executed_by_a_state_feedback_when_system_is_started() {
        let exp = expectation(description: "ViewState factory is called by feedback")
        
        let expectedInitialState = MockState(value: Int.random(in: 1...1_000_000))
        let expectedState = MockState(value: Int.random(in: 1...1_000_000))
        
        let expectedInitialViewState = MockViewState.undefined
        let expectedViewState1 = MockViewState(value: expectedInitialState.value)
        let expectedViewState2 = MockViewState(value: expectedState.value)

        var receivedViewState = [MockViewState]()
        
        // Given: a UISystem that outputs a ViewState
        let sut = UISystem(viewStateFactory: { systemState -> MockViewState in
            switch systemState {
            case let mockState as MockState:
                return MockViewState(value: mockState.value)
            default:
                return MockViewState.undefined
            }
        },
        initialState: InitialState { expectedInitialState },
        feedbacks: Feedbacks {},
        stateMachine: StateMachine {
            Transition(from: MockState.self, on: MockEvent.self, then: expectedState)
        },
        systemScheduler: DispatchQueue.immediateScheduler,
        viewStateScheduler: DispatchQueue.immediateScheduler)
                
        // When: listening for the different view state produced by the UISystem
        let viewStateCancellable = sut.$state.output(in: 0...2).sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { receivedViewState.append($0) })
        let sutCancellable = sut.stream.sink { _ in }
        
        // When: emitting a "user event" in the UISystem so a new ViewState is produced
        sut.emit(MockEvent(value: 1))
        
        waitForExpectations(timeout: 0.5)

        // Then: 3 ViewStates are generated: 1 -> undefined, 2 -> from initial state, 3 -> from the user event
        XCTAssertEqual(receivedViewState, [expectedInitialViewState, expectedViewState1, expectedViewState2])

        viewStateCancellable.cancel()
        sutCancellable.cancel()
    }
    
    func test_viewStateFactory_is_executed_on_the_expected_queue() {
        let exp = expectation(description: "view state factory")
        let expectedViewStateFactoryQueue = "VIEWSTATE.\(UUID().uuidString)"
        var receivedViewStateFactoryQueue = ""
        
        // Given: a UISystem that records the execution queue of the viewStateFactory function
        let sut = UISystem(viewStateFactory: { systemState -> MockViewState in
            receivedViewStateFactoryQueue = DispatchQueue.currentLabel
            exp.fulfill()
            return MockViewState(value: 1)
        },
        initialState: InitialState { MockState(value: 1) },
        feedbacks: Feedbacks {},
        stateMachine: StateMachine {
            Transition(from: MockState.self, on: MockEvent.self, then: MockState(value: 1))
        },
        systemScheduler: DispatchQueue.immediateScheduler,
        viewStateScheduler: DispatchQueue(label: expectedViewStateFactoryQueue))
        
        // When: running the UISystem
        let cancellable = sut.stream.sink { _ in }
        
        waitForExpectations(timeout: 0.5)

        // Then: the viewStateFactory is executed on the expected queue for the initial state
        XCTAssertEqual(receivedViewStateFactoryQueue, expectedViewStateFactoryQueue)
        
        cancellable.cancel()
    }
    
    func testInit_add_an_event_feedback() {
        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        var receivedEvent: Event?
        
        // Given: a UISystem that records the events emitted by the feedbacks
        let sut = UISystem(viewStateFactory: { systemState -> MockViewState in
            MockViewState(value: Int.random(in: 0...1_000_000))
        }) {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }
            
            Feedbacks {}
                .onEventEmitted { receivedEvent = $0 }
            
            StateMachine {}
        }
        .execute(on: DispatchQueue.immediateScheduler)
        
        let cancellable = sut.stream.sink { _ in }
        
        // When: emitting a "user event" with the UISystem
        sut.emit(expectedEvent)
        
        // Then: the event is sent for the system's feedbacks, meaning that a dedicated feedback has been added to the system
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)
        
        cancellable.cancel()
    }
    
    func testViewState_is_produced_on_mainQueue_even_if_system_and_viewStateFactory_are_executed_on_their_dedicated_queues() {
        let exp = expectation(description: "viewState on main queue")
        
        var receivedQueue = ""
        let expectedQueue = "com.apple.main-thread"

        // Given: a UISystem that has dedicated schedulers for the feedbacks, the view state factory and the reducer
        let sut = UISystem(viewStateFactory: { systemState -> MockViewState in
            return MockViewState(value: (systemState as! MockState).value)
        },
        initialState: InitialState { MockState(value: 1701) },
        feedbacks: Feedbacks {
            Feedback { _ in Empty().eraseToAnyPublisher() }.execute(on: DispatchQueue(label: UUID().uuidString))
        },
        stateMachine: StateMachine {
            Transition(from: MockState.self, on: MockEvent.self) { state, event in
                return MockState(value: state.value + event.value)
            }
        },
        systemScheduler: DispatchQueue(label: UUID().uuidString),
        viewStateScheduler: DispatchQueue(label: UUID().uuidString),
        extraStateRenderFunction: { state in
            receivedQueue = DispatchQueue.currentLabel
            exp.fulfill()
        })
                
        // When: running the system
        let cancellable = sut.stream.sink { _ in }

        waitForExpectations(timeout: 0.5)

        // Then: the view state assignation is on the main queue
        XCTAssertEqual(receivedQueue, expectedQueue)
        
        cancellable.cancel()
    }
}

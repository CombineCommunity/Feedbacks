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
private struct MockViewState: ViewState {
    let value: Int
    
    static var undefined: MockViewState {
        MockViewState(value: -1)
    }
}
private struct MockEvent: Event, Equatable { let value: Int }

final class UISystemTests: XCTestCase {
    func testUISystem_provide_a_decorator_for_rawState() {
        // Given: a system
        let system = System {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }
            Feedbacks {}

            Transitions {
                From(MockState.self) { _ in
                    On(MockEvent.self) { _ in MockState(value: 10) }
                }
            }
        }

        // when: making a RawState UISystem from it
        let sut = system.uiSystem()

        // Then: the UISystem has the expected specifications
        XCTAssertEqual(sut.initialState.value as? MockState, system.initialState.value as? MockState)
        XCTAssertEqual(sut.feedbacks.feedbacks.count, system.feedbacks.feedbacks.count + 2) // 2 UI feedbacks are added to the UISystem
        XCTAssertEqual(sut.transitions.transitions.count, system.transitions.transitions.count)
        XCTAssertEqual(sut.transitions.reducer(MockState(value: 1), MockEvent(value: 1)) as? MockState,
                       system.transitions.reducer(MockState(value: 1), MockEvent(value: 1)) as? MockState)
    }

    func testMakePublishingFeedback_execute_publishing_on_main_queue() {
        let exp = expectation(description: "execute viewStateFactory on expected")

        let expectedQueue = "com.apple.main-thread"
        var receivedQueue = ""

        // Given: a state publishing Feedback recording the publishing queue
        let sut = UISystem.makeStatePublishingFeedback(publishingFunction: { _ in receivedQueue = DispatchQueue.currentLabel})

        // when: making a ViewState UISystem from it, executing the view state factory in a dedicated queue
        let cancellable = sut
            .sideEffect(Just(MockState(value: 1)).eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })

        waitForExpectations(timeout: 0.5)

        cancellable.cancel()

        // Then: the Feedback published the state on the main queue
        XCTAssertEqual(receivedQueue, expectedQueue)
    }

    func testMakePublishingFeedback_receive_state_in_publishingFunction() {
        let exp = expectation(description: "receives RawState to publish")

        let expectedState = MockState(value: Int.random(in: 0...1_000_000))
        var receivedState: RawState?

        // Given: a state publishing Feedback recording the received state for the publishing function
        let sut = UISystem.makeStatePublishingFeedback(publishingFunction: { receivedState = $0 })

        // when: running the feedback
        let cancellable = sut
            .sideEffect(Just(expectedState).eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })

        waitForExpectations(timeout: 0.5)

        cancellable.cancel()

        // Then: the publishing function receives the expected state
        XCTAssertEqual(receivedState?.state as? MockState, expectedState)
    }

    func testUISystem_publish_states_when_initialized_and_event_is_emitted() {
        let exp = expectation(description: "publish RawState")

        let initialState = MockState(value: Int.random(in: 0...1_000_000))
        let mutatedState = MockState(value: Int.random(in: 0...1_000_000))
        let expectedStates = [initialState, initialState, mutatedState]
        var receivedRawStates = [RawState]()

        // Given: a RawState UISystem
        let sut = UISystem {
            InitialState {
                initialState
            }
            Feedbacks {}

            Transitions {
                From(MockState.self) { _ in
                    On(MockEvent.self) { _ in mutatedState }
                }
            }
        }
        .execute(on: DispatchQueue.immediateScheduler)

        let stateCancellable = sut.$state.output(in: 0...2).sink(receiveCompletion: { _ in exp.fulfill() },
                                                                 receiveValue: { receivedRawStates.append($0) })
        let cancellable = sut.stream.sink(receiveValue: { _ in })

        sut.emit(MockEvent(value: 1))

        waitForExpectations(timeout: 0.5)

        XCTAssertEqual(receivedRawStates.map { $0.state } as? [MockState], expectedStates)

        cancellable.cancel()
        stateCancellable.cancel()
    }

    func testUISystem_for_rawState_execute_system_on_default_background_queue() {
        let exp = expectation(description: "execute on default queue")

        let expectedQueue = System.defaultQueue.label
        var receivedQueue = ""

        // Given: a RawState UISystem
        let sut = UISystem {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }

            Feedbacks {
                Feedback(on: MockState.self, strategy: .continueOnNewState) { state in
                    return Just<Event>(MockEvent(value: 1)).setFailureType(to: Never.self).eraseToAnyPublisher()
                }
            }

            Transitions {
                From(MockState.self) {
                    On(MockEvent.self) {
                        receivedQueue = DispatchQueue.currentLabel
                        return MockState(value: 1)
                    }
                }
            }
        }

        let cancellable = sut.stream.output(in: 0...1).sink(receiveCompletion: { _ in exp.fulfill()}, receiveValue: { _ in })

        sut.emit(MockEvent(value: 1))

        waitForExpectations(timeout: 0.5)

        XCTAssertEqual(receivedQueue, expectedQueue)

        cancellable.cancel()
    }

    func testUISystem_provide_a_decorator_for_viewState() {
        // Given: a system
        let sut = System {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }
            Feedbacks { }

            Transitions {
                From(MockState.self) { _ in
                    On(MockEvent.self) { _ in MockState(value: 10) }
                }
            }
        }

        // when: making a ViewState UISystem from it
        let uiSystem = sut.uiSystem(viewStateFactory: { _ in MockViewState(value: Int.random(in: 0...1_000_000)) })

        // Then: the UISystem has the expected specifications
        XCTAssertEqual(uiSystem.initialState.value as? MockState, sut.initialState.value as? MockState)
        XCTAssertEqual(uiSystem.feedbacks.feedbacks.count, sut.feedbacks.feedbacks.count + 2) // 2 UI feedbacks are added to the UISystem
        XCTAssertEqual(uiSystem.transitions.transitions.count, sut.transitions.transitions.count)
        XCTAssertEqual(uiSystem.transitions.reducer(MockState(value: 1), MockEvent(value: 1)) as? MockState,
                       sut.transitions.reducer(MockState(value: 1), MockEvent(value: 1)) as? MockState)

    }

    func testMakePublishingFeedback_execute_viewStateFactory_on_expected_queue() {
        let exp = expectation(description: "execute viewStateFactory on expected queue")

        let expectedQueue = "VIEWSTATEFACTORY-\(UUID().uuidString)"
        var receivedQueue = ""

        // Given: a Feedback for ViewState publishing
        let sut = UISystem.makeStatePublishingFeedback(
            viewStateFactory: { _ -> MockViewState in
                receivedQueue = DispatchQueue.currentLabel
                exp.fulfill()
                return MockViewState(value: Int.random(in: 0...1_000_000))
            },
            on: DispatchQueue(label: expectedQueue),
            publishingFunction: { _ in })

        // when: running that feedback
        let cancellable = sut
            .sideEffect(Just(MockState(value: 1)).eraseToAnyPublisher())
            .sink(receiveValue: { _ in })

        waitForExpectations(timeout: 0.5)

        cancellable.cancel()

        // Then: the viewStateFactory function is executed on the expected queue
        XCTAssertEqual(receivedQueue, expectedQueue)
    }

    func testMakePublishingFeedback_execute_publishing_on_main_queue_for_viewState() {
        let exp = expectation(description: "execute viewStateFactory on expected")

        let expectedQueue = "com.apple.main-thread"
        var receivedQueue = ""

        // Given: a viewState publishing Feedback recording the publishing queue
        let sut = UISystem.makeStatePublishingFeedback(
            viewStateFactory: { _ -> MockViewState in
                return MockViewState(value: Int.random(in: 0...1_000_000))
            },
            on: DispatchQueue(label: UUID().uuidString),
            publishingFunction: { _ in
                receivedQueue = DispatchQueue.currentLabel
            })

        // when: running the feedback
        let cancellable = sut
            .sideEffect(Just(MockState(value: 1)).eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })

        waitForExpectations(timeout: 0.5)

        cancellable.cancel()

        // Then: the Feedback published the state on the main queue
        XCTAssertEqual(receivedQueue, expectedQueue)
    }

    func testMakePublishingFeedback_receive_viewState_in_publishingFunction() {
        let exp = expectation(description: "receives ViewState to publish")

        let expectedState = MockViewState(value: Int.random(in: 0...1_000_000))
        var receivedState: MockViewState?

        // Given: a state publishing Feedback recording the received state for the publishing function
        let sut = UISystem.makeStatePublishingFeedback(
            viewStateFactory: { _ -> MockViewState in
                return expectedState
            },
            on: DispatchQueue(label: UUID().uuidString),
            publishingFunction: { receivedState = $0 })

        // when: running the feedback
        let cancellable = sut
            .sideEffect(Just(MockState(value: 1)).eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })

        waitForExpectations(timeout: 0.5)

        cancellable.cancel()

        // Then: the publishing function receives the expected viewState
        XCTAssertEqual(receivedState, expectedState)
    }

    func testMakePublishingFeedback_publish_distinct_viewStates() {
        let exp = expectation(description: "receives ViewState to publish")

        let expectedStates = [MockViewState(value: 1), MockViewState(value: 2), MockViewState(value: 3)]
        var receivedStates = [MockViewState]()

        let inputStateSubject = PassthroughSubject<State, Never>()

        // Given: a state publishing Feedback recording the received state for the publishing function
        let sut = UISystem.makeStatePublishingFeedback(
            viewStateFactory: { state -> MockViewState in
                if let mockState = state as? MockState {
                    return MockViewState(value: mockState.value)
                }
                return MockViewState(value: -1)
            },
            on: DispatchQueue(label: UUID().uuidString),
            publishingFunction: { receivedStates.append($0) })

        // when: running the feedback, with two first equal states
        let cancellable = sut
            .sideEffect(inputStateSubject.eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })

        inputStateSubject.send(MockState(value: 1))
        inputStateSubject.send(MockState(value: 1))
        inputStateSubject.send(MockState(value: 2))
        inputStateSubject.send(MockState(value: 2))
        inputStateSubject.send(MockState(value: 3))
        inputStateSubject.send(completion: .finished)

        waitForExpectations(timeout: 0.5)

        cancellable.cancel()

        // Then: the publishing function receives the distinct viewStates
        XCTAssertEqual(receivedStates, expectedStates)
    }

    func testUISystem_publish_viewState_when_initialized_and_event_is_emitted() {
        let exp = expectation(description: "initialViewStates Are .Undefined and the Ones from initialState and mutatedState")

        let initialState = MockState(value: Int.random(in: 0...1_000_000))
        let mutatedState = MockState(value: Int.random(in: 0...1_000_000))
        let expectedStates = [initialState, mutatedState]
        let expectedViewStates = [MockViewState.undefined,
                                  MockViewState(value: initialState.value),
                                  MockViewState(value: mutatedState.value)]

        var receivedStates = [State]()
        var receivedViewStates = [MockViewState]()

        // Given: a ViewState UISystem
        let sut = UISystem(viewStateFactory: { state -> MockViewState in
            receivedStates.append(state)
            return MockViewState(value: (state as! MockState).value)
        }, on: DispatchQueue.immediateScheduler) {
            InitialState {
                initialState
            }
            Feedbacks {}

            Transitions {
                From(MockState.self) { _ in
                    On(MockEvent.self) { _ in mutatedState }
                }
            }
        }
        .execute(on: DispatchQueue.immediateScheduler)


        // When: starting the stream
        let stateCancellable = sut.$state.output(in: 0...2).sink(receiveCompletion: { _ in exp.fulfill()}) { receivedViewStates.append($0) }
        let cancellable = sut.stream.sink(receiveValue: { _ in })

        // When: emitting an event to mutate the state
        sut.emit(MockEvent(value: 1))

        waitForExpectations(timeout: 0.5)

        // Then: the [initialState, mutatedEvent] are given as an input to the viewFactoryFunction
        XCTAssertEqual(receivedStates as? [MockState], expectedStates)
        // Then: the ViewState is first the undefined ViewState and then the ViewStates from the mapping of the initialState and the mutatedState
        XCTAssertEqual(receivedViewStates, expectedViewStates)

        cancellable.cancel()
        stateCancellable.cancel()
    }

    func testUISystem_for_viewState_execute_system_on_default_background_queue() {
        let exp = expectation(description: "execute on default queue")

        let expectedQueue = System.defaultQueue.label
        var receivedQueue = ""

        // Given: a ViewState UISystem
        let sut = UISystem(viewStateFactory: { _ in MockViewState(value: 1)}) {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }

            Feedbacks {
                Feedback(on: MockState.self, strategy: .continueOnNewState) { state in
                    return Just<Event>(MockEvent(value: 1)).setFailureType(to: Never.self).eraseToAnyPublisher()
                }
            }

            Transitions {
                From(MockState.self) {
                    On(MockEvent.self) {
                        receivedQueue = DispatchQueue.currentLabel
                        return MockState(value: 1)
                    }
                }
            }
        }

        let cancellable = sut.stream.output(in: 0...1).sink(receiveCompletion: { _ in exp.fulfill()}, receiveValue: { _ in })

        sut.emit(MockEvent(value: 1))

        waitForExpectations(timeout: 0.5)

        XCTAssertEqual(receivedQueue, expectedQueue)

        cancellable.cancel()
    }

    func testUISystem_output_an_event_when_emit_is_called() {
        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        var receivedEvent: Event?

        // Given: a UISystem that records the events emitted by the feedbacks
        let sut = UISystem {
            InitialState {
                MockState(value: Int.random(in: 0...1_000_000))
            }

            Feedbacks {}
                .onEventEmitted { receivedEvent = $0 }

            Transitions {}
        }
        .execute(on: DispatchQueue.immediateScheduler)

        let cancellable = sut.stream.sink { _ in }

        // When: emitting a "user event" with the UISystem
        sut.emit(expectedEvent)

        // Then: the event is sent for the system's feedbacks, meaning that a dedicated feedback has been added to the system
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        cancellable.cancel()
    }

    func testUIFeedback_execute_viewStateFactory_on_expected_queue_when_instantiated_from_system() {
        let exp = expectation(description: "viewStateFactory Scheduler Is Respected")
        let expectedViewStateFactoryQueue = "VIEWSTATE.\(UUID().uuidString)"
        var receivedViewStateFactoryQueue = ""

        // Given: a UISystem that records the execution queue of the viewStateFactory function
        let system = System {
            InitialState { MockState(value: 1) }
            Feedbacks {}
            Transitions {
                From(MockState.self) { _ in
                    On(MockEvent.self) { _ in MockState(value: 1) }
                }
            }
        }
        .execute(on: DispatchQueue.immediateScheduler)

        let sut = system.uiSystem(
            viewStateFactory: { systemState -> MockViewState in
                receivedViewStateFactoryQueue = DispatchQueue.currentLabel
                exp.fulfill()
                return MockViewState(value: 1)
            },
            on: DispatchQueue(label: expectedViewStateFactoryQueue))

        // When: running the UISystem
        let cancellable = sut.stream.sink { _ in }

        waitForExpectations(timeout: 0.5)

        // Then: the viewStateFactory is executed on the expected queue for the initial state
        XCTAssertEqual(receivedViewStateFactoryQueue, expectedViewStateFactoryQueue)

        cancellable.cancel()
    }
}

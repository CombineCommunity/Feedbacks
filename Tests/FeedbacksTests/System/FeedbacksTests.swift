//
//  FeedbacksTests.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-28.
//

import Combine
@testable import Feedbacks
import XCTest

private struct MockStateA: State, Equatable { let value: Int }
private struct MockStateB: State {}

private struct MockEvent: Event, Equatable { let value: Int }

final class FeedbacksTests: XCTestCase {
    func testInit_set_the_feedback_array() {
        // Given: some Feedbacks
        // When: building a Feedbacks with those Feedbacks thanks to a @FeedbacksBuilder
        let sut = Feedbacks {
            Feedback { _ in Empty().eraseToAnyPublisher() }
            Feedback { _ in Empty().eraseToAnyPublisher() }
            Feedback { _ in Empty().eraseToAnyPublisher() }
        }

        // Then: the inner array has the input feedbacks
        XCTAssertEqual(sut.feedbacks.count, 3)
    }
}

// MARK: tests for Feedbacks.onStateReceived(:)
extension FeedbacksTests {
    func testOnStateReceived_call_the_perform() {
        let expectedState = MockStateA(value: Int.random(in: 0...1_000_000))
        var receivedState: State?

        // Given: a Feedbacks, recording the received states with `onStateReceived(:)`
        let sut = Feedbacks {
            Feedback { _ in Just<Event>(MockEvent(value: 1)).eraseToAnyPublisher() }
        }.onStateReceived {
            receivedState = $0
        }.execute(on: DispatchQueue.immediateScheduler)

        // When: executing the event stream from the side effects
        let cancellable = sut.eventStream(Just(expectedState).eraseToAnyPublisher()).sink(receiveValue: { _ in })

        // Then: the `onStateReceived` callback is called with the expected state
        XCTAssertEqual(receivedState as? MockStateA, expectedState)

        cancellable.cancel()
    }
}

// MARK: tests for Feedbacks.onEventEmitted(:)
extension FeedbacksTests {
    func testOnEventEmitted_call_the_perform() {
        let expectedEvent = MockEvent(value: Int.random(in: 1...1_000_000))
        var receivedEvent: Event?

        // Given: a Feedbacks, recording the received event with `onEventEmitted(:)`
        let sut = Feedbacks {
            Feedback { _ in Just<Event>(expectedEvent).eraseToAnyPublisher() }
        }.onEventEmitted {
            receivedEvent = $0
        }
        .execute(on: DispatchQueue.immediateScheduler)

        // When: executing the event stream from the side effects
        let cancellable = sut.eventStream(Just(MockStateA(value: 1)).eraseToAnyPublisher()).sink(receiveValue: { _ in })

        // Then: the `onEventEmitted` callback is called with the expected event
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        cancellable.cancel()
    }
}

// MARK: tests for Feedbacks.execute(on:)
extension FeedbacksTests {
    func testExecute_execute_all_sideEffects_on_expected_scheduler() {
        let exp = expectation(description: "Feedbacks.execute(on:)")

        let expectedQueueA = UUID().uuidString
        let expectedQueueB = UUID().uuidString
        var receivedQueuesA = [String]()
        var receivedQueuesB = [String]()

        // Given: a Feedbacks composed of feedbacks which side effect are recording there execution queues
        let sut = Feedbacks {
            Feedback(on: MockStateA.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
                receivedQueuesA.append(DispatchQueue.currentLabel)
                return Just(MockEvent(value: 1)).eraseToAnyPublisher()
            }
            .execute(on: DispatchQueue(label: expectedQueueA))

            Feedback(on: MockStateA.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
                receivedQueuesB.append(DispatchQueue.currentLabel)
                return Just(MockEvent(value: 1)).eraseToAnyPublisher()
            }
        }
        .execute(on: DispatchQueue(label: expectedQueueB))

        // When: executing all the Feedbacks's side effects
        let cancellable = sut
            .eventStream(Just(MockStateA(value: 1)).eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })

        waitForExpectations(timeout: 0.5)

        // Then: the side effects are executed on the expected queue
        receivedQueuesA.forEach { XCTAssertEqual($0, expectedQueueA) }
        receivedQueuesB.forEach { XCTAssertEqual($0, expectedQueueB) }

        cancellable.cancel()
    }
}


// MARK: tests for FeedbacksBuilder.buildBlock(:)
extension FeedbacksTests {
    func testBuildBlock_return_inputs_as_array() {
        var feedbackAIsCalled = false
        var feedbackBIsCalled = false

        // Given: two feedbacks
        let inputFeedbackA = Feedback(on: AnyState.self, strategy: .continueOnNewState) { state in
            feedbackAIsCalled = true
            return Empty<Event, Never>().eraseToAnyPublisher()
        }
        
        let inputFeedbackB = Feedback(on: AnyState.self, strategy: .continueOnNewState) { state in
            feedbackBIsCalled = true
            return Empty<Event, Never>().eraseToAnyPublisher()
        }

        // When: building an array of feedbacks thanks to FeedbacksBuilder and executing those feedbacks
        let sut = FeedbacksBuilder.buildBlock(inputFeedbackA, inputFeedbackB)

        let sideEffects = sut.map { $0.sideEffect(Just(MockStateA(value: 1)).eraseToAnyPublisher()) }
        let cancellable = Publishers.MergeMany(sideEffects).sink { _ in }

        // Then: the input feedbacks have been used to build the array of feedbacks
        XCTAssertTrue(feedbackAIsCalled)
        XCTAssertTrue(feedbackBIsCalled)

        cancellable.cancel()
    }
}

// MARK: tests for Feedbacks.add(feedback:)
extension FeedbacksTests {
    func testAdd_add_a_feedback() {
        var sideEffectIsExecuted = false
        
        // Given: an empty Feedabcks
        let sut = Feedbacks {}
        
        // When: adding a feedback that records its execution
        let newFeedbacks = sut.add(feedback: Feedback(on: AnyState.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
            sideEffectIsExecuted = true
            return Empty().eraseToAnyPublisher()
        }.execute(on: DispatchQueue.immediateScheduler))
        
        // when: executing the feedbacks
        let cancellable = newFeedbacks.eventStream(Just(MockStateA(value: 1)).eraseToAnyPublisher()).sink(receiveValue: { _ in })
        
        // Then: the added feedback is executed
        XCTAssertTrue(sideEffectIsExecuted)
        
        cancellable.cancel()
    }
}

// MARK: tests for Feedbacks.attach()
extension FeedbacksTests {
    func testAttach_catch_the_mediator_value_when_closure_and_emit_the_expectedEvent() {
        let randomValue = Int.random(in: 1...1_000_000)
        var receivedEvent: Event?
        let expectedEvent = MockEvent(value: randomValue)

        // Given: a mediator that handles Integer values
        // Given: a Feedbacks that is attached to this mediator and trigger a MockEvent when the mediator's value is equal to randomValue
        // Given: a spy `onEventEmitted` modifier that records Events from the stream
        let mediator = PassthroughMediator<Int>()
        let sut = Feedbacks {
            Feedback { _ in Empty().eraseToAnyPublisher() }
        }
        .attach(to: mediator,
                emitSystemEvent: {
                    $0 == randomValue ? MockEvent(value: $0) : nil
                })
        .onEventEmitted { receivedEvent = $0 }
        .execute(on: DispatchQueue.immediateScheduler)

        // When: executing the underlying reactive stream
        let cancellable = sut.eventStream(Just(MockStateA(value: 0)).eraseToAnyPublisher()).sink(receiveValue: { _ in })

        // When: the mediator output a value that does not match the `attach` criteria
        mediator.send(randomValue-1)
        // Then: no event is sent by the Feedbacks
        XCTAssertNil(receivedEvent)

        // When: the mediator output a value that does match the `attach` criteria
        mediator.send(randomValue)
        // Then: the expected event is sent by the Feedbacks
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        // When: the mediator output a value that does not match the `attach` criteria
        mediator.send(randomValue-2)
        // Then: no event is sent by the Feedbacks
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        cancellable.cancel()
    }

    func testAttach_catch_the_mediator_value_and_emit_the_expectedEvent_when_state_as_an_input() {
        let randomValue = Int.random(in: 1...1_000_000)
        var receivedEvent: Event?
        let expectedEvent = MockEvent(value: randomValue)

        // Given: a mediator that handles Integer values
        // Given: a Feedbacks that is attached to this mediator and trigger a MockEvent when the mediator's value is equal to randomValue
        // Given: a spy `onEventEmitted` modifier that records Events from the stream
        let mediator = PassthroughMediator<Int>()
        let sut = Feedbacks {
            Feedback { _ in Empty().eraseToAnyPublisher() }
        }
        .attach(to: mediator,
                onMediatorValue: randomValue,
                emitSystemEvent: { MockEvent(value: $0) })
        .onEventEmitted { receivedEvent = $0 }
        .execute(on: DispatchQueue.immediateScheduler)

        // When: executing the underlying reactive stream
        let cancellable = sut.eventStream(Just(MockStateA(value: 0)).eraseToAnyPublisher()).sink(receiveValue: { _ in })

        // When: the mediator output a value that does not match the `attach` criteria
        mediator.send(randomValue-1)
        // Then: no event is sent by the Feedbacks
        XCTAssertNil(receivedEvent)

        // When: the mediator output a value that does match the `attach` criteria
        mediator.send(randomValue)
        // Then: the expected event is sent by the Feedbacks
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        // When: the mediator output a value that does not match the `attach` criteria
        mediator.send(randomValue-2)
        // Then: no event is sent by the Feedbacks
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        cancellable.cancel()
    }

    func testAttach_catch_the_mediator_value_and_emit_the_expectedEvent() {
        let randomValue = Int.random(in: 1...1_000_000)
        var receivedEvent: Event?
        let expectedEvent = MockEvent(value: randomValue)

        // Given: a mediator that handles Integer values
        // Given: a Feedbacks that is attached to this mediator and trigger a MockEvent when the mediator's value is equal to randomValue
        // Given: a spy `onEventEmitted` modifier that records Events from the stream
        let mediator = PassthroughMediator<Int>()
        let sut = Feedbacks {
            Feedback { _ in Empty().eraseToAnyPublisher() }
        }
        .attach(to: mediator,
                onMediatorValue: randomValue,
                emitSystemEvent: expectedEvent)
        .onEventEmitted { receivedEvent = $0 }
        .execute(on: DispatchQueue.immediateScheduler)

        // When: executing the underlying reactive stream
        let cancellable = sut.eventStream(Just(MockStateA(value: 0)).eraseToAnyPublisher()).sink(receiveValue: { _ in })

        // When: the mediator output a value that does not match the `attach` criteria
        mediator.send(randomValue-1)
        // Then: no event is sent by the Feedbacks
        XCTAssertNil(receivedEvent)

        // When: the mediator output a value that does match the `attach` criteria
        mediator.send(randomValue)
        // Then: the expected event is sent by the Feedbacks
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        // When: the mediator output a value that does not match the `attach` criteria
        mediator.send(randomValue-2)
        // Then: no event is sent by the Feedbacks
        XCTAssertEqual(receivedEvent as? MockEvent, expectedEvent)

        cancellable.cancel()
    }

    func testAttach_catch_the_feedbacks_state_when_closure_and_emit_the_expectedMediatorValue() {
        let expectedValue = Int.random(in: 1...1_000_000)

        // Given: a mediator that handles Integer values
        // Given: a Feedbacks that is attached to this mediator and propagates a new value when the state is MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = Feedbacks {
            Feedback { _ in Empty().eraseToAnyPublisher() }
        }
        .attach(to: mediator,
                emitMediatorValue: { $0 is MockStateA ? expectedValue : nil })
        .execute(on: DispatchQueue.immediateScheduler)

        let inputStateSubject = PassthroughSubject<State, Never>()

        // When: executing the underlying reactive stream
        let cancellable = sut.eventStream(inputStateSubject.eraseToAnyPublisher()).sink(receiveValue: { _ in })

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB())
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, -1)

        // When: the system's state is MockStateA
        inputStateSubject.send(MockStateA(value: 1701))
        // Then: the expected value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB())
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        cancellable.cancel()
    }
    
    func testAttach_catch_the_feedbacks_stateType_and_emit_the_expectedMediatorValue_when_state_iS_given_as_an_input() {
        let expectedValue = Int.random(in: 1...1_000_000)

        // Given: a mediator that handles Integer values
        // Given: a Feedbacks that is attached to this mediator and propagates a new value when the state is of type MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = Feedbacks {
            Feedback { _ in Empty().eraseToAnyPublisher() }
        }
        .attach(to: mediator,
                onSystemStateType: MockStateA.self,
                emitMediatorValue: { $0.value })
        .execute(on: DispatchQueue.immediateScheduler)

        let inputStateSubject = PassthroughSubject<State, Never>()

        // When: executing the underlying reactive stream
        let cancellable = sut.eventStream(inputStateSubject.eraseToAnyPublisher()).sink(receiveValue: { _ in })

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB())
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, -1)

        // When: the system's state is MockStateA
        inputStateSubject.send(MockStateA(value: expectedValue))
        // Then: the expected value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB())
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        cancellable.cancel()
    }

    func testAttach_catch_the_feedbacks_stateType_and_emit_the_expectedMediatorValue() {
        let expectedValue = Int.random(in: 1...1_000_000)

        // Given: a mediator that handles Integer values
        // Given: a Feedbacks that is attached to this mediator and propagates a new value when the state is of type MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = Feedbacks {
            Feedback { _ in Empty().eraseToAnyPublisher() }
        }
        .attach(to: mediator,
                onSystemStateType: MockStateA.self,
                emitMediatorValue: expectedValue)
        .execute(on: DispatchQueue.immediateScheduler)

        let inputStateSubject = PassthroughSubject<State, Never>()

        // When: executing the underlying reactive stream
        let cancellable = sut.eventStream(inputStateSubject.eraseToAnyPublisher()).sink(receiveValue: { _ in })

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB())
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, -1)

        // When: the system's state is MockStateA
        inputStateSubject.send(MockStateA(value: 1701))
        // Then: the expected value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB())
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        cancellable.cancel()
    }
    
    func testAttach_catch_the_feedbacks_state_and_emit_the_expectedMediatorValue_when_state_is_given_as_an_input() {
        let expectedValue = Int.random(in: 1...1_000_000)

        // Given: a mediator that handles Integer values
        // Given: a Feedbacks that is attached to this mediator and propagates a new value when the state is equal to a specific MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = Feedbacks {
            Feedback { _ in Empty().eraseToAnyPublisher() }
        }
        .attach(to: mediator,
                onSystemState: MockStateA(value: expectedValue),
                emitMediatorValue: { $0.value })
        .execute(on: DispatchQueue.immediateScheduler)

        let inputStateSubject = PassthroughSubject<State, Never>()

        // When: executing the underlying reactive stream
        let cancellable = sut.eventStream(inputStateSubject.eraseToAnyPublisher()).sink(receiveValue: { _ in })

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB())
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, -1)

        // When: the system's state is MockStateA
        inputStateSubject.send(MockStateA(value: expectedValue))
        // Then: the expected value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB())
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        cancellable.cancel()
    }

    func testAttach_catch_the_feedbacks_state_and_emit_the_expectedMediatorValue() {
        let expectedValue = Int.random(in: 1...1_000_000)

        // Given: a mediator that handles Integer values
        // Given: a Feedbacks that is attached to this mediator and propagates a new value when the state is equal to a specific MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = Feedbacks {
            Feedback { _ in Empty().eraseToAnyPublisher() }
        }
        .attach(to: mediator,
                onSystemState: MockStateA(value: expectedValue),
                emitMediatorValue: expectedValue)
        .execute(on: DispatchQueue.immediateScheduler)

        let inputStateSubject = PassthroughSubject<State, Never>()

        // When: executing the underlying reactive stream
        let cancellable = sut.eventStream(inputStateSubject.eraseToAnyPublisher()).sink(receiveValue: { _ in })

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB())
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, -1)

        // When: the system's state is MockStateA
        inputStateSubject.send(MockStateA(value: expectedValue))
        // Then: the expected value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB())
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        cancellable.cancel()
    }
}

//
//  FeedbackTests.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-27.
//

import Combine
import CombineSchedulers
@testable import Feedbacks
import XCTest

private struct MockStateA: State, Equatable { let value: Int }
private struct MockStateB: State, Equatable {}

private struct MockEvent: Event, Equatable { let value: Int }
private struct MockEventA: Event, Equatable { let value: Int }
private struct MockEventB: Event, Equatable {}

final class FeedbackTests: XCTestCase {}

// MARK: tests for Feedback.init(sideEffect:)
extension FeedbackTests {
    func testInit_use_the_sideEffect_without_alteration() {
        let expectedState = MockStateA(value: Int.random(in: 1...1_000_000))
        var receivedStates = [State]()
        
        let expectedEvent = MockEventA(value: Int.random(in: 1...1_000_000))
        var receivedEvents = [Event]()
        
        // Given: a sideEffect recording its input States and emitting an expected Event
        let spySideEffect: (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> = { states in
            states
                .handleEvents(receiveOutput: { receivedStates.append($0) })
                .map { _ in expectedEvent }
                .eraseToAnyPublisher()
        }
        
        // When: making a feedback of it, and executing it with an expected input State
        let sut = Feedback(sideEffect: spySideEffect)
        
        let cancellable = sut.sideEffect(Just(expectedState).eraseToAnyPublisher()).sink { receivedEvents.append($0) }
        
        // Then: the side effect used to build the Feedback is used as expected
        XCTAssertEqual(receivedStates.count, 1)
        XCTAssertEqual(receivedStates[0] as? MockStateA, expectedState)
        
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(receivedEvents[0] as? MockEventA, expectedEvent)
        
        cancellable.cancel()
    }
}

// MARK: tests for Feedback.init(on:sideEffect:)
extension FeedbackTests {
    func testInit_give_anyStates_to_the_sideEffect_when_publisher() {
        let expectedState = MockStateA(value: Int.random(in: 1...1_000_000))
        var receivedStates = [State]()

        let expectedEvent = MockEventA(value: Int.random(in: 1...1_000_000))
        var receivedEvents = [Event]()

        // Given: a Feedback receiving AnyStates
        let sut = Feedback(on: AnyState.self) { (states: AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> in
            states
                .handleEvents(receiveOutput: { receivedStates.append($0) })
                .map { _ in expectedEvent }
                .eraseToAnyPublisher()
        }.execute(on: DispatchQueue.immediateScheduler)

        // When: running the feedback with a MockStateA
        let cancellable = sut.sideEffect(Just(expectedState).eraseToAnyPublisher()).sink { receivedEvents.append($0) }

        // Then: the side effect used to build the Feedback is used as expected
        XCTAssertEqual(receivedStates.count, 1)
        XCTAssertEqual(receivedStates[0] as? MockStateA, expectedState)

        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(receivedEvents[0] as? MockEventA, expectedEvent)

        cancellable.cancel()
    }
}


// MARK: tests for Feedback.init(on:strategy:sideEffect:)
extension FeedbackTests {
    func testInit_give_anyState_to_the_sideEffect_when_strategy() {
        let expectedStrategy = Feedback.Strategy.continueOnNewState
        var receivedStrategy: Feedback.Strategy?

        let expectedState = MockStateA(value: Int.random(in: 1...1_000_000))
        var receivedStates = [State]()

        let expectedEvent = MockEventA(value: Int.random(in: 1...1_000_000))
        var receivedEvents = [Event]()

        // Given: a Feedback receiving an AnyState
        let sut = Feedback(on: AnyState.self,
                           strategy: expectedStrategy,
                           willExecuteWithStrategy: { receivedStrategy = $0 }) { (state: State) -> AnyPublisher<Event, Never> in
            receivedStates.append(state)
            return Just(expectedEvent)
                .eraseToAnyPublisher()
        }.execute(on: DispatchQueue.immediateScheduler)

        // When: running the feedback with a MockStateA
        let cancellable = sut.sideEffect(Just(expectedState).eraseToAnyPublisher()).sink { receivedEvents.append($0) }

        // Then: the side effect used to build the Feedback is used as expected
        XCTAssertEqual(receivedStates.count, 1)
        XCTAssertEqual(receivedStates[0] as? MockStateA, expectedState)

        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(receivedEvents[0] as? MockEventA, expectedEvent)

        XCTAssertEqual(receivedStrategy, expectedStrategy)

        cancellable.cancel()
    }
}


// MARK: tests for Feedback.init(on:sideEffect) with a concrete state
extension FeedbackTests {
    func testInit_give_concreteStates_to_the_sideEffect_when_publisher() {
        let expectedState = MockStateA(value: Int.random(in: 1...1_000_000))
        var receivedStates = [State]()

        let expectedEvent = MockEventA(value: Int.random(in: 0...1_000_000))
        var receivedEvents = [Event]()

        let inputStateStream = PassthroughSubject<State, Never>()

        // Given: a sideEffect for a concrete state, recording whether it is called or not, and emitting an expected Even
        let sut = Feedback(on: MockStateA.self) { (states: AnyPublisher<MockStateA, Never>) -> AnyPublisher<Event, Never> in
            states
                .handleEvents(receiveOutput: { receivedStates.append($0) })
                .map { _ in expectedEvent }
                .eraseToAnyPublisher()
        }.execute(on: DispatchQueue.immediateScheduler)

        let cancellable = sut.sideEffect(inputStateStream.eraseToAnyPublisher()).sink { receivedEvents.append($0) }

        // Then: the side effect used to build the Feedback is called only for the expected concrete input state
        inputStateStream.send(MockStateB())
        XCTAssertTrue(receivedStates.isEmpty)

        inputStateStream.send(expectedState)
        XCTAssertEqual(receivedStates[0] as? MockStateA, expectedState)

        // Then: the side effect used to build the Feedback is used as expected
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(receivedEvents[0] as? MockEventA, expectedEvent)

        cancellable.cancel()
    }
}

// MARK: tests for Feedback.init(on:strategy:sideEffect) with a concrete state
extension FeedbackTests {
    func testInit_give_concreteState_to_the_sideEffect_when_strategy() {
        let expectedStrategy = Feedback.Strategy.continueOnNewState
        var receivedStrategy: Feedback.Strategy?

        let expectedState = MockStateA(value: Int.random(in: 1...1_000_000))
        var receivedStates = [State]()

        let expectedEvent = MockEventA(value: Int.random(in: 1...1_000_000))
        var receivedEvents = [Event]()

        let inputStateStream = PassthroughSubject<State, Never>()

        // Given: a Feedback receiving a concrete state
        let sut = Feedback(on: MockStateA.self,
                           strategy: expectedStrategy,
                           willExecuteWithStrategy: { receivedStrategy = $0 }) { state -> AnyPublisher<Event, Never> in
            receivedStates.append(state)
            return Just(expectedEvent)
                .eraseToAnyPublisher()
        }.execute(on: DispatchQueue.immediateScheduler)

        // When: running the feedback with a MockStateA
        let cancellable = sut.sideEffect(inputStateStream.eraseToAnyPublisher()).sink { receivedEvents.append($0) }

        // Then: the side effect used to build the Feedback is called only for the expected concrete input state
        inputStateStream.send(MockStateB())
        XCTAssertTrue(receivedStates.isEmpty)

        inputStateStream.send(expectedState)
        XCTAssertEqual(receivedStates[0] as? MockStateA, expectedState)

        // Then: the side effect used to build the Feedback is used as expected
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(receivedEvents[0] as? MockEventA, expectedEvent)

        XCTAssertEqual(receivedStrategy, expectedStrategy)

        cancellable.cancel()
    }
}

// MARK: tests for Feedback.execute(on:)
extension FeedbackTests {
    func testExecute_execute_sideEffect_on_expected_scheduler() {
        let exp = expectation(description: "Feedback.execute(on:)")
        
        let expectedQueue = UUID().uuidString
        var receivedQueue = ""
        
        // Given: a side effect recording its execution queue
        let spySideEffect: (MockStateA) -> AnyPublisher<Event, Never> = { state in
            receivedQueue = DispatchQueue.currentLabel
            return Just(MockEventA(value: 1)).eraseToAnyPublisher()
        }
        
        // When: making a Feedback of it, and executing it on the expected Queue
        let sut = Feedback(on: MockStateA.self, strategy: .continueOnNewState, perform: spySideEffect)
            .execute(on: DispatchQueue(label: expectedQueue))
        
        let cancellable = sut.sideEffect(Just(MockStateA(value: 1)).eraseToAnyPublisher()).sink{ _ in exp.fulfill() }
        
        waitForExpectations(timeout: 0.5)
        
        // Then: the side effect is executed on the expected queue
        XCTAssertEqual(receivedQueue, expectedQueue)
        
        cancellable.cancel()
    }
}

// MARK: tests for Feedback.disable(:)
extension FeedbackTests {
    func testDisable_dynamically_disable_sideEffect() {
        var sideEffectIsCalled = false
        
        var isDisabled = true
        
        // Given: a side effect recording its execution
        let spySideEffect: (State) -> AnyPublisher<Event, Never> = { _ in
            sideEffectIsCalled = true
            return Empty().eraseToAnyPublisher()
        }
        
        // When: making a feedback of it, with a disable(:) modifier
        let sut = Feedback(on: AnyState.self, strategy: .continueOnNewState, perform: spySideEffect).disable { isDisabled }
        
        let inputStateStream = PassthroughSubject<State, Never>()
        
        // When: executing that feedback
        let cancellable = sut.sideEffect(inputStateStream.eraseToAnyPublisher()).sink { _ in }
        
        // When: sending a new state as an input while the feedback is disabled
        inputStateStream.send(MockStateA(value: 1))
        
        // Then: the side effect is not executed
        XCTAssertFalse(sideEffectIsCalled)
        
        // When: sending a new state as an input while the feedback is enabled
        isDisabled = false
        inputStateStream.send(MockStateA(value: 2))
        
        // Then: the side effect is executed
        XCTAssertTrue(sideEffectIsCalled)
        
        cancellable.cancel()
    }
}

// MARK: tests for Feedback.onStateReceived(:)
extension FeedbackTests {
    func testOnStateReceived_call_the_perform() {
        let expectedState = MockStateA(value: Int.random(in: 0...1_000_000))
        var receivedState: State?
        
        // Given: a Feedback, recording the received states with `onStateReceived(:)`
        let sut = Feedback { (states: AnyPublisher<State, Never>) in
            states.map { _ in MockEventA(value: 1) }.eraseToAnyPublisher()
        }.onStateReceived {
            receivedState = $0
        }
        
        // When: executing the side effect
        let cancellable = sut.sideEffect(Just(expectedState).eraseToAnyPublisher()).sink(receiveValue: { _ in })
        
        // Then: the `onStateReceived` callback is called with the expected state
        XCTAssertEqual(receivedState as? MockStateA, expectedState)
        
        cancellable.cancel()
    }
}

// MARK: tests for Feedback.onEventEmitted(:)
extension FeedbackTests {
    func testOnEventEmitted_call_the_perform() {
        let expectedEvent = MockEventA(value: Int.random(in: 1...1_000_000))
        var receivedEvent: Event?
        
        // Given: a Feedback, recording the received states with `onEventEmitted(:)`
        let sut = Feedback { (states: AnyPublisher<State, Never>) in
            states.map { _ in expectedEvent }.eraseToAnyPublisher()
        }.onEventEmitted {
            receivedEvent = $0
        }
        
        // When: executing the side effect
        let cancellable = sut.sideEffect(Just(MockStateB()).eraseToAnyPublisher()).sink(receiveValue: { _ in })
        
        // Then: the `onEventEmitted` callback is called with the expected event
        XCTAssertEqual(receivedEvent as? MockEventA, expectedEvent)
        
        cancellable.cancel()
    }
}

// MARK: tests for Feedback.Strategy
extension FeedbackTests {
    func testApply_produce_a_sideEffect_that_continues_when_a_new_state_occurs() {
        // Virtual timeline:
        // now--------------1-------------2--------------3-----------4
        // |                |             |              |           |
        // subscribe    MockStateA    MockStateB    MockEventA   MockEventB
        //
        // with continueOnNewState, we expect that MockEventA will not be discarded when MockStateB occurs
        let scheduler = DispatchQueue.testScheduler
        var receivedEvents: [Event] = []
        
        // Given: a state input stream the triggers a MockStateA at 1s, and a MockStateB at 2s
        let stateInputStream = PassthroughSubject<State, Never>()
        
        scheduler.schedule(after: scheduler.now.advanced(by: 1)) {
            print("Sending MockStateA at \(scheduler.now.dispatchTime.uptimeNanoseconds)")
            stateInputStream.send(MockStateA(value: 1))
        }
        scheduler.schedule(after: scheduler.now.advanced(by: 2)) {
            print("Sending MockStateB at \(scheduler.now.dispatchTime.uptimeNanoseconds)")
            stateInputStream.send(MockStateB())
        }
        
        // Given: a side effect that emits MockEventA for MockStateA and MockEventB for MockState2
        let sideEffect: (State) -> AnyPublisher<Event, Never> = { state in
            switch state {
            case is MockStateA:
                return Just(MockEventA(value: 1))
                    .delay(for: .seconds(2), scheduler: scheduler)
                    .handleEvents(receiveOutput: { _ in print("Sending MockEventA at \(scheduler.now.dispatchTime.uptimeNanoseconds)") })
                    .eraseToAnyPublisher()
            case is MockStateB:
                return Just(MockEventB())
                    .delay(for: .seconds(2), scheduler: scheduler)
                    .handleEvents(receiveOutput: { _ in print("Sending MockEventB at \(scheduler.now.dispatchTime.uptimeNanoseconds)") })
                    .eraseToAnyPublisher()
            default:
                return Empty().eraseToAnyPublisher()
            }
        }
        
        // When: executing the side effect with a continueOnNewState strategy and listening for the output events
        let sut = Feedback.Strategy.continueOnNewState.apply(on: sideEffect)
        
        let cancellable = sut(stateInputStream.eraseToAnyPublisher()).sink { receivedEvents.append($0) }
        
        scheduler.run()
        
        // Then: both events are triggered. The first execution (MockStateA -> MockEventA) is not cancelled
        XCTAssertEqual(receivedEvents.count, 2)
        XCTAssertEqual(receivedEvents[0] as? MockEventA, MockEventA(value: 1))
        XCTAssertEqual(receivedEvents[1] as? MockEventB, MockEventB())
        
        cancellable.cancel()
    }
    
    func testApply_produce_a_sideEffect_that_cancels_when_a_new_state_occurs() {
        // Virtual timeline:
        // now--------------1-------------2--------------3-----------4
        // |                |             |              |           |
        // subscribe    MockStateA    MockStateB         |      MockEventB
        //                                               |
        //                                          ❌MockEventA is cancelled
        //
        // with cancelOnNewState, we expect that MockEventA will be discarded when MockStateB occurs
        let scheduler = DispatchQueue.testScheduler
        var receivedEvents: [Event] = []
        
        // Given: a state input stream the triggers a MockStateA at 1s, and a MockStateB at 2s
        let stateInputStream = PassthroughSubject<State, Never>()
        
        scheduler.schedule(after: scheduler.now.advanced(by: 1)) {
            print("Sending MockStateA at \(scheduler.now.dispatchTime.uptimeNanoseconds)")
            stateInputStream.send(MockStateA(value: 1))
        }
        scheduler.schedule(after: scheduler.now.advanced(by: 2)) {
            print("Sending MockStateB at \(scheduler.now.dispatchTime.uptimeNanoseconds)")
            stateInputStream.send(MockStateB())
        }
        
        // Given: a side effect that emits MockEventA for MockStateA and MockEventB for MockState2
        let sideEffect: (State) -> AnyPublisher<Event, Never> = { state in
            switch state {
            case is MockStateA:
                return Just(MockEventA(value: 1))
                    .delay(for: .seconds(2), scheduler: scheduler)
                    .handleEvents(receiveCancel: { print("Cancelling MockEventA at \(scheduler.now.dispatchTime.uptimeNanoseconds)") })
                    .eraseToAnyPublisher()
            case is MockStateB:
                return Just(MockEventB())
                    .delay(for: .seconds(2), scheduler: scheduler)
                    .handleEvents(receiveOutput: { _ in print("Sending MockEventB at \(scheduler.now.dispatchTime.uptimeNanoseconds)") })
                    .eraseToAnyPublisher()
            default:
                return Empty().eraseToAnyPublisher()
            }
        }
        
        // When: executing the side effect with a cancelOnNewState strategy and listening for the output events
        let sut = Feedback.Strategy.cancelOnNewState.apply(on: sideEffect)
        
        let cancellable = sut(stateInputStream.eraseToAnyPublisher()).sink { receivedEvents.append($0) }
        
        scheduler.run()
        
        // Then: both events are triggered. The first execution (MockStateA -> MockEventA) is not cancelled
        XCTAssertEqual(receivedEvents.count, 1)
        XCTAssertEqual(receivedEvents[0] as? MockEventB, MockEventB())
        
        cancellable.cancel()
    }
}

// MARK: tests for Feedback.init() for mediators
extension FeedbackTests {
    func testAttach_catch_the_mediator_value_when_closure_and_emit_the_expectedEvent() {
        let randomValue = Int.random(in: 1...1_000_000)
        var receivedEvent: Event?
        let expectedEvent = MockEvent(value: randomValue)
        
        // Given: a mediator that handles Integer values
        // Given: a Feedback that is attached to this mediator and trigger a MockEvent when the mediator's value is equal to randomValue
        // Given: a spy `onEventEmitted` modifier that records Events from the stream
        let mediator = PassthroughMediator<Int>()
        let sut = Feedback(mediator: mediator,
                           emitSystemEvent: {
                            $0 == randomValue ? MockEvent(value: $0) : nil
                           })
            .onEventEmitted { receivedEvent = $0 }
            .execute(on: DispatchQueue.immediateScheduler)
        
        // When: executing the underlying reactive stream
        let cancellable = sut.sideEffect(Just(MockStateA(value: 0)).eraseToAnyPublisher()).sink(receiveValue: { _ in })
        
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
        // Given: a Feedback that is attached to this mediator and trigger a MockEvent when the mediator's value is equal to randomValue
        // Given: a spy `onEventEmitted` modifier that records Events from the stream
        let mediator = PassthroughMediator<Int>()
        let sut = Feedback(mediator: mediator,
                           onMediatorValue: randomValue,
                           emitSystemEvent: { MockEvent(value: $0) })
            .onEventEmitted { receivedEvent = $0 }
            .execute(on: DispatchQueue.immediateScheduler)
        
        // When: executing the underlying reactive stream
        let cancellable = sut.sideEffect(Just(MockStateA(value: 0)).eraseToAnyPublisher()).sink(receiveValue: { _ in })
        
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
        // Given: a Feedback that is attached to this mediator and trigger a MockEvent when the mediator's value is equal to randomValue
        // Given: a spy `onEventEmitted` modifier that records Events from the stream
        let mediator = PassthroughMediator<Int>()
        let sut = Feedback(mediator: mediator,
                           onMediatorValue: randomValue,
                           emitSystemEvent: expectedEvent)
            .onEventEmitted { receivedEvent = $0 }
            .execute(on: DispatchQueue.immediateScheduler)
        
        // When: executing the underlying reactive stream
        let cancellable = sut.sideEffect(Just(MockStateA(value: 0)).eraseToAnyPublisher()).sink(receiveValue: { _ in })
        
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
        // Given: a Feedback that is attached to this mediator and propagates a new value when the state is MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = Feedback(mediator: mediator,
                           emitMediatorValue: { $0 is MockStateA ? expectedValue : nil })
            .execute(on: DispatchQueue.immediateScheduler)
        
        let inputStateSubject = PassthroughSubject<State, Never>()
        
        // When: executing the underlying reactive stream
        let cancellable = sut.sideEffect(inputStateSubject.eraseToAnyPublisher()).sink(receiveValue: { _ in })
        
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
        // Given: a Feedback that is attached to this mediator and propagates a new value when the state is of type MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = Feedback(mediator: mediator,
                           onSystemStateType: MockStateA.self,
                           emitMediatorValue: { $0.value })
            .execute(on: DispatchQueue.immediateScheduler)
        
        let inputStateSubject = PassthroughSubject<State, Never>()
        
        // When: executing the underlying reactive stream
        let cancellable = sut.sideEffect(inputStateSubject.eraseToAnyPublisher()).sink(receiveValue: { _ in })
        
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
        // Given: a Feedback that is attached to this mediator and propagates a new value when the state is of type MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = Feedback(mediator: mediator,
                           onSystemStateType: MockStateA.self,
                           emitMediatorValue: expectedValue)
            .execute(on: DispatchQueue.immediateScheduler)
        
        let inputStateSubject = PassthroughSubject<State, Never>()
        
        // When: executing the underlying reactive stream
        let cancellable = sut.sideEffect(inputStateSubject.eraseToAnyPublisher()).sink(receiveValue: { _ in })
        
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
        // Given: a Feedback that is attached to this mediator and propagates a new value when the state is equal to a specific MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = Feedback(mediator: mediator,
                           onSystemState: MockStateA(value: expectedValue),
                           emitMediatorValue: { $0.value })
            .execute(on: DispatchQueue.immediateScheduler)
        
        let inputStateSubject = PassthroughSubject<State, Never>()
        
        // When: executing the underlying reactive stream
        let cancellable = sut.sideEffect(inputStateSubject.eraseToAnyPublisher()).sink(receiveValue: { _ in })
        
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
        // Given: a Feedback that is attached to this mediator and propagates a new value when the state is equal to a specific MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = Feedback(mediator: mediator,
                           onSystemState: MockStateA(value: expectedValue),
                           emitMediatorValue: expectedValue)
            .execute(on: DispatchQueue.immediateScheduler)
        
        let inputStateSubject = PassthroughSubject<State, Never>()
        
        // When: executing the underlying reactive stream
        let cancellable = sut.sideEffect(inputStateSubject.eraseToAnyPublisher()).sink(receiveValue: { _ in })
        
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


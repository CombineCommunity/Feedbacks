//
//  SystemTests.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-28.
//

import Combine
import CombineSchedulers
@testable import Feedbacks
import XCTest

private struct MockStateA: State, Equatable { let value: Int }
private struct MockStateB: State, Equatable { let value: Int }
private struct MockStateC: State, Equatable { let value: Int }
private struct MockStateD: State, Equatable { let value: Int }

private struct MockNextEvent: Event, Equatable {}
private struct MockEventA: Event, Equatable { let value: Int}

final class SystemTests: XCTestCase {
    func testStream_make_a_stream_where_initialState_is_given_to_feedbacks() {
        let exp = expectation(description: "initial state")
        
        let expectedState = MockStateA(value: Int.random(in: 0...1_000_000))
        var receivedStates = [State]()
        
        // Given: a system that records the state incoming in its side effects
        let sut = System {
            InitialState {
                expectedState
            }
            
            Feedbacks {
                Feedback(on: AnyState.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
                    receivedStates.append(state)
                    return Just<Event>(MockNextEvent()).eraseToAnyPublisher()
                }
            }
            
            Transitions {
                From(AnyState.self) { _ in
                    On(AnyEvent.self) { _ in
                        MockStateB(value: 1)
                    }
                }
            }
        }
        
        // When: executing the system and completing after a first state is processed
        let cancellable = sut
            .stream
            .output(in: 0...1)
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })
        
        waitForExpectations(timeout: 0.5)
        
        // Then: the first state received by the side effect is the initial state
        XCTAssertEqual(receivedStates[0] as? MockStateA, expectedState)
        
        cancellable.cancel()
    }
    
    func testStream_make_a_stream_that_respect_schedulers() {
        let exp = expectation(description: "Schedulers")
        
        let expectedFeedbackAQueue = "FEEDBACKA-\(UUID().uuidString)"
        let expectedFeedbackBQueue = "FEEDBACKB-\(UUID().uuidString)"
        let expectedSystemQueue = "SYSTEM-\(UUID().uuidString)"
        
        var receivedFeedbackAQueue = [String]()
        var receivedFeedbackBQueue = [String]()
        var receivedSystemQueue = [String]()
        
        // Given: a system recording the execution queues for side effects and reducer
        // Given: a system that executes side effects and reducer on dedicated schedulers
        @SystemBuilder var system: System {
            InitialState {
                MockStateA(value: 1)
            }
            
            Feedbacks {
                Feedback(on: MockStateA.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
                    receivedFeedbackAQueue.append(DispatchQueue.currentLabel)
                    return Just<Event>(MockNextEvent()).eraseToAnyPublisher()
                }
                .execute(on: DispatchQueue(label: expectedFeedbackAQueue))
                
                Feedback(on: MockStateB.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
                    receivedFeedbackBQueue.append(DispatchQueue.currentLabel)
                    return Just<Event>(MockNextEvent()).eraseToAnyPublisher()
                }
                .execute(on: DispatchQueue(label: expectedFeedbackBQueue))
            }
            
            Transitions {
                From(MockStateA.self) { state in
                    On(MockNextEvent.self) { _ in
                        receivedSystemQueue.append(DispatchQueue.currentLabel)
                        return MockStateB(value: state.value)
                    }
                }
                
                From(MockStateB.self) { state in
                    On(MockNextEvent.self) { _ in
                        receivedSystemQueue.append(DispatchQueue.currentLabel)
                        return MockStateA(value: state.value + 1)
                    }
                }
            }
        }

        let sut = system.execute(on: DispatchQueue(label: expectedSystemQueue))
        
        // When: executing that system
        let cancellable = sut
            .stream
            .output(in: 0...2)
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })
        
        waitForExpectations(timeout: 0.5)
        
        // Then: the side effects and reducers happen on the expected queues
        receivedFeedbackAQueue.forEach { XCTAssertEqual($0, expectedFeedbackAQueue) }
        receivedFeedbackBQueue.forEach { XCTAssertEqual($0, expectedFeedbackBQueue) }
        receivedSystemQueue.forEach { XCTAssertEqual($0, expectedSystemQueue) }
        
        cancellable.cancel()
    }
    
    func testStream_make_a_stream_that_execute_on_systemScheduler() {
        let exp = expectation(description: "Schedulers")
        
        let expectedReducerQueue = "SYSTEM-\(UUID().uuidString)"
        var receivedSystemQueue = [String]()
        
        // Given: a system recording the execution queues for side effects and reducer
        let sut = System {
            InitialState {
                MockStateA(value: 1)
            }
            
            Feedbacks {
                Feedback(on: MockStateA.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
                    receivedSystemQueue.append(DispatchQueue.currentLabel)
                    return Just<Event>(MockNextEvent()).eraseToAnyPublisher()
                }
                
                Feedback(on: MockStateB.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
                    receivedSystemQueue.append(DispatchQueue.currentLabel)
                    return Just<Event>(MockNextEvent()).eraseToAnyPublisher()
                }
            }
            
            Transitions {
                From(MockStateA.self) { state in
                    On(MockNextEvent.self) { _ in
                        receivedSystemQueue.append(DispatchQueue.currentLabel)
                        return MockStateB(value: state.value)
                    }
                }
                
                From(MockStateB.self) { state in
                    On(MockNextEvent.self) { _ in
                        receivedSystemQueue.append(DispatchQueue.currentLabel)
                        return MockStateA(value: state.value + 1)
                    }
                }
            }
        }
        .execute(on: DispatchQueue(label: expectedReducerQueue))
        
        // When: executing that system on a unique scheduler
        let cancellable = sut
            .stream
            .output(in: 0...2)
            .sink(receiveCompletion: { _ in exp.fulfill() }, receiveValue: { _ in })
        
        waitForExpectations(timeout: 0.5)
        
        // Then: the side effects and reducers happen on the expected queue
        receivedSystemQueue.forEach { XCTAssertEqual($0, expectedReducerQueue) }
        
        cancellable.cancel()
    }
    
    func testStream_produce_a_predictable_feedback_execution_order() {
        let exp = expectation(description: "predictable system")
        let expectedStates: [State] = [MockStateA(value: 1),
                                       MockStateB(value: 1),
                                       MockStateC(value: 1),
                                       MockStateD(value: 1),
                                       MockStateA(value: 2),
                                       MockStateB(value: 2),
                                       MockStateC(value: 2),
                                       MockStateD(value: 2)]
        var receivedStatesInFeedbackA = [State]()
        var receivedStatesInFeedbackB = [State]()
        var receivedStatesInFeedbackC = [State]()
        var receivedStatesInFeedbackD = [State]()
        
        // Given: a system with 4 feedbacks that are concerned by only one state, given a reducer supposed to generate
        // an ordered progression of those states
        let sut = System {
            InitialState {
                MockStateA(value: 1)
            }
            
            Feedbacks {
                Feedback(on: AnyState.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
                    receivedStatesInFeedbackA.append(state)
                    guard state is MockStateA else { return Empty().eraseToAnyPublisher() }
                    return Just<Event>(MockNextEvent()).eraseToAnyPublisher()
                }
                .execute(on: DispatchQueue(label: UUID().uuidString))
                
                Feedback(on: AnyState.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
                    receivedStatesInFeedbackB.append(state)
                    guard state is MockStateB else { return Empty().eraseToAnyPublisher() }
                    return Just<Event>(MockNextEvent()).eraseToAnyPublisher()
                }
                .execute(on: DispatchQueue(label: UUID().uuidString))
                
                Feedback(on: AnyState.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
                    receivedStatesInFeedbackC.append(state)
                    guard state is MockStateC else { return Empty().eraseToAnyPublisher() }
                    return Just<Event>(MockNextEvent()).eraseToAnyPublisher()
                }
                .execute(on: DispatchQueue(label: UUID().uuidString))
                
                Feedback(on: AnyState.self, strategy: .continueOnNewState) { state -> AnyPublisher<Event, Never> in
                    receivedStatesInFeedbackD.append(state)
                    guard state is MockStateD else { return Empty().eraseToAnyPublisher() }
                    return Just<Event>(MockNextEvent()).eraseToAnyPublisher()
                }
                .execute(on: DispatchQueue(label: UUID().uuidString))
            }
            
            Transitions {
                From(MockStateA.self) { state in
                    On(MockNextEvent.self) { _ in MockStateB(value: state.value) }
                }
                
                From(MockStateB.self) { state in
                    On(MockNextEvent.self) { _ in MockStateC(value: state.value) }
                }
                
                From(MockStateC.self) { state in
                    On(MockNextEvent.self) { _ in MockStateD(value: state.value) }
                }
                
                From(MockStateD.self) { state in
                    On(MockNextEvent.self) { _ in MockStateA(value: state.value + 1) }
                }
            }
        }.execute(on: DispatchQueue(label: UUID().uuidString))
        
        // When: executing the system
        let cancellable = sut
            .stream
            .output(in: 0...9)
            .sink(receiveCompletion: { _ in exp.fulfill() } , receiveValue: { _ in })
        
        waitForExpectations(timeout: 0.5)
        
        // Then: the feedbacks are receiving the expected state in the expected order
        self.assertStatesAreTheExpectedOnes(received: receivedStatesInFeedbackA, expected: expectedStates)
        self.assertStatesAreTheExpectedOnes(received: receivedStatesInFeedbackB, expected: expectedStates)
        self.assertStatesAreTheExpectedOnes(received: receivedStatesInFeedbackC, expected: expectedStates)
        self.assertStatesAreTheExpectedOnes(received: receivedStatesInFeedbackD, expected: expectedStates)
        
        cancellable.cancel()
    }

    func testRun_starts_the_stream() {
        var streamIsStarted = false

        // Given: a system
        let sut = System {
            InitialState {
                MockStateA(value: 1)
            }

            Feedbacks {
                Feedback { _ in Empty().eraseToAnyPublisher() }
            }
            .onStateReceived { _ in
                streamIsStarted = true
            }

            Transitions {
                From(MockStateA.self) { _ in
                    On(MockNextEvent.self) { _ in MockStateB(value: 2) }
                }
            }
        }
        .execute(on: DispatchQueue.immediateScheduler)

        // When: running it
        let newSystem = sut.run()

        // Then: the system is started
        XCTAssertTrue(streamIsStarted)
        // Then: the returned system is the original one
        XCTAssert(newSystem === sut)
    }
    
    func testAttach_catch_the_mediator_value_when_closure_and_emit_the_expectedEvent() {
        let mediator = PassthroughMediator<Int>()
        
        let expectedEvent = MockEventA(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?
        
        // Given: a system attached to a mediator that emits Integer values
        let sut = System {
            InitialState {
                MockStateA(value: 1)
            }
            
            Feedbacks {
                Feedback { _ in Empty().eraseToAnyPublisher() }
            }
            
            Transitions {
                From(MockStateA.self) {
                    On(MockNextEvent.self, transitionTo: MockStateB(value: 2))
                }
            }
        }
        .attach(to: mediator, emitSystemEvent: { $0 == 1701 ? expectedEvent : nil })
        .execute(on: DispatchQueue.immediateScheduler)
        
        // When: executing the last added feedback to the system
        let cancellable = sut
            .feedbacks
            .feedbacks
            .last!
            .sideEffect(Just(MockStateA(value: 1)).eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in }, receiveValue: { receivedEvent = $0 })
        
        // When: the mediator output a value that does not match the `attach` criteria
        mediator.send(0)
        // Then: no event is sent by the feedback
        XCTAssertNil(receivedEvent)
        
        // When: the mediator output a value that does match the `attach` criteria
        mediator.send(1701)
        // Then: the expected event is sent by the feedback
        XCTAssertEqual(receivedEvent as? MockEventA, expectedEvent)
        
        cancellable.cancel()
    }
    
    func testAttach_catch_the_mediator_value_and_emit_the_expectedEvent_when_value_is_given_as_an_input() {
        let mediator = PassthroughMediator<Int>()
        
        let expectedEvent = MockEventA(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?
        
        // Given: a system attached to a mediator that emits Integer values
        let sut = System {
            InitialState {
                MockStateA(value: 1)
            }
            
            Feedbacks {
                Feedback { _ in Empty().eraseToAnyPublisher() }
            }
            
            Transitions {
                From(MockStateA.self) { _ in
                    On(MockNextEvent.self) { _ in MockStateB(value: 2) }
                }
            }
        }
        .attach(to: mediator, onMediatorValue: 1701 , emitSystemEvent: { _ in expectedEvent })
        .execute(on: DispatchQueue.immediateScheduler)
        
        // When: executing the last added feedback to the system
        let cancellable = sut
            .feedbacks
            .feedbacks
            .last!
            .sideEffect(Just(MockStateA(value: 1)).eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in }, receiveValue: { receivedEvent = $0 })
        
        // When: the mediator output a value that does not match the `attach` criteria
        mediator.send(0)
        // Then: no event is sent by the feedback
        XCTAssertNil(receivedEvent)
        
        // When: the mediator output a value that does match the `attach` criteria
        mediator.send(1701)
        // Then: the expected event is sent by the feedback
        XCTAssertEqual(receivedEvent as? MockEventA, expectedEvent)
        
        cancellable.cancel()
    }

    func testAttach_catch_the_mediator_value_and_emit_the_expectedEvent() {
        let mediator = PassthroughMediator<Int>()

        let expectedEvent = MockEventA(value: Int.random(in: 0...1_000_000))
        var receivedEvent: Event?

        // Given: a system attached to a mediator that emits Integer values
        let sut = System {
            InitialState {
                MockStateA(value: 1)
            }

            Feedbacks {
                Feedback { _ in Empty().eraseToAnyPublisher() }
            }

            Transitions {
                From(MockStateA.self) { _ in
                    On(MockNextEvent.self) { _ in MockStateB(value: 2) }
                }
            }
        }
        .attach(to: mediator, onMediatorValue: 1701 , emitSystemEvent: expectedEvent)
        .execute(on: DispatchQueue.immediateScheduler)

        // When: executing the last added feedback to the system
        let cancellable = sut
            .feedbacks
            .feedbacks
            .last!
            .sideEffect(Just(MockStateA(value: 1)).eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in }, receiveValue: { receivedEvent = $0 })

        // When: the mediator output a value that does not match the `attach` criteria
        mediator.send(0)
        // Then: no event is sent by the feedback
        XCTAssertNil(receivedEvent)

        // When: the mediator output a value that does match the `attach` criteria
        mediator.send(1701)
        // Then: the expected event is sent by the feedback
        XCTAssertEqual(receivedEvent as? MockEventA, expectedEvent)

        cancellable.cancel()
    }
    
    func testAttach_catch_the_feedbacks_state_when_closure_and_emit_the_expectedMediatorValue() {
        let expectedValue = Int.random(in: 1...1_000_000)
        
        // Given: a mediator that handles Integer values
        // Given: a System that is attached to this mediator and propagates a new value when the state is MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = System {
            InitialState {
                MockStateA(value: 1)
            }
            
            Feedbacks {
                Feedback { _ in Empty().eraseToAnyPublisher() }
            }
            
            Transitions {
                From(MockStateA.self) { _ in
                    On(MockNextEvent.self) { _ in MockStateB(value: 2) }
                }
            }
        }
        .attach(to: mediator,
                emitMediatorValue: { $0 is MockStateA ? expectedValue : nil })
        .execute(on: DispatchQueue.immediateScheduler)
        
        let inputStateSubject = PassthroughSubject<State, Never>()
        
        // When: executing the last added feedback to the system
        let cancellable = sut
            .feedbacks
            .feedbacks
            .last!
            .sideEffect(inputStateSubject.eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB(value: 1))
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, -1)
        
        // When: the system's state is MockStateA
        inputStateSubject.send(MockStateA(value: 1701))
        // Then: the expected value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)
        
        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB(value: 2))
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)
        
        cancellable.cancel()
    }
    
    func testAttach_catch_the_feedbacks_stateType_and_emit_the_expectedMediatorValue_when_state_is_given_as_an_input() {
        let expectedValue = Int.random(in: 1...1_000_000)
        
        // Given: a mediator that handles Integer values
        // Given: a System that is attached to this mediator and propagates a new value when the state is MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = System {
            InitialState {
                MockStateA(value: 1)
            }
            
            Feedbacks {
                Feedback { _ in Empty().eraseToAnyPublisher() }
            }
            
            Transitions {
                From(MockStateA.self) { _ in
                    On(MockNextEvent.self) { _ in MockStateB(value: 2) }
                }
            }
        }
        .attach(to: mediator,
                onSystemStateType: MockStateA.self,
                emitMediatorValue: { $0.value })
        .execute(on: DispatchQueue.immediateScheduler)
        
        let inputStateSubject = PassthroughSubject<State, Never>()
        
        // When: executing the last added feedback to the system
        let cancellable = sut
            .feedbacks
            .feedbacks
            .last!
            .sideEffect(inputStateSubject.eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB(value: 1))
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, -1)
        
        // When: the system's state is MockStateA
        inputStateSubject.send(MockStateA(value: expectedValue))
        // Then: the expected value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)
        
        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB(value: 2))
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)
        
        cancellable.cancel()
    }

    func testAttach_catch_the_feedbacks_stateType_and_emit_the_expectedMediatorValue() {
        let expectedValue = Int.random(in: 1...1_000_000)

        // Given: a mediator that handles Integer values
        // Given: a System that is attached to this mediator and propagates a new value when the state is MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = System {
            InitialState {
                MockStateA(value: 1)
            }

            Feedbacks {
                Feedback { _ in Empty().eraseToAnyPublisher() }
            }

            Transitions {
                From(MockStateA.self) { _ in
                    On(MockNextEvent.self) { _ in MockStateB(value: 2) }
                }
            }
        }
        .attach(to: mediator,
                onSystemStateType: MockStateA.self,
                emitMediatorValue: expectedValue)
        .execute(on: DispatchQueue.immediateScheduler)

        let inputStateSubject = PassthroughSubject<State, Never>()

        // When: executing the last added feedback to the system
        let cancellable = sut
            .feedbacks
            .feedbacks
            .last!
            .sideEffect(inputStateSubject.eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB(value: 1))
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, -1)

        // When: the system's state is MockStateA
        inputStateSubject.send(MockStateA(value: expectedValue))
        // Then: the expected value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB(value: 2))
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        cancellable.cancel()
    }
    
    func testAttach_catch_the_feedbacks_state_and_emit_the_expectedMediatorValue_when_state_is_given_as_an_input() {
        let expectedValue = Int.random(in: 1...1_000_000)
        
        // Given: a mediator that handles Integer values
        // Given: a System that is attached to this mediator and propagates a new value when the state is MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = System {
            InitialState {
                MockStateA(value: 1)
            }
            
            Feedbacks {
                Feedback { _ in Empty().eraseToAnyPublisher() }
            }
            
            Transitions {
                From(MockStateA.self) {
                    On(MockNextEvent.self, transitionTo: MockStateB(value: 2))
                }
            }
        }
        .attach(to: mediator,
                onSystemState: MockStateA(value: expectedValue),
                emitMediatorValue: { $0.value })
        .execute(on: DispatchQueue.immediateScheduler)
        
        let inputStateSubject = PassthroughSubject<State, Never>()
        
        // When: executing the last added feedback to the system
        let cancellable = sut
            .feedbacks
            .feedbacks
            .last!
            .sideEffect(inputStateSubject.eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
        
        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB(value: 1))
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, -1)
        
        // When: the system's state is MockStateA
        inputStateSubject.send(MockStateA(value: expectedValue))
        // Then: the expected value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)
        
        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB(value: 2))
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)
        
        cancellable.cancel()
    }

    func testAttach_catch_the_feedbacks_state_and_emit_the_expectedMediatorValue() {
        let expectedValue = Int.random(in: 1...1_000_000)

        // Given: a mediator that handles Integer values
        // Given: a System that is attached to this mediator and propagates a new value when the state is MockStateA
        let mediator = CurrentValueMediator<Int>(-1)
        let sut = System {
            InitialState {
                MockStateA(value: 1)
            }

            Feedbacks {
                Feedback { _ in Empty().eraseToAnyPublisher() }
            }

            Transitions {
                From(MockStateA.self) {
                    On(MockNextEvent.self, transitionTo: MockStateB(value: 2))
                }
            }
        }
        .attach(to: mediator,
                onSystemState: MockStateA(value: expectedValue),
                emitMediatorValue: expectedValue)
        .execute(on: DispatchQueue.immediateScheduler)

        let inputStateSubject = PassthroughSubject<State, Never>()

        // When: executing the last added feedback to the system
        let cancellable = sut
            .feedbacks
            .feedbacks
            .last!
            .sideEffect(inputStateSubject.eraseToAnyPublisher())
            .sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB(value: 1))
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, -1)

        // When: the system's state is MockStateA
        inputStateSubject.send(MockStateA(value: expectedValue))
        // Then: the expected value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        // When: the system's state is MockStateB
        inputStateSubject.send(MockStateB(value: 2))
        // Then: no value is propagated to the mediator
        XCTAssertEqual(mediator.value, expectedValue)

        cancellable.cancel()
    }

    func testAttach_emit_event_in_another_system_when_state_is_expected() {
        let randomValue = Int.random(in: 1...1_000_000)

        let expectedEventB = MockEventA(value: randomValue)
        var receivedEventB: Event?

        let sutAInputEventStream = PassthroughSubject<Event, Never>()

        // Given: 2 attached systems, from MockStateB state type to MockEventA event
        let sutA = System {
            InitialState {
                MockStateA(value: 1)
            }

            Feedbacks {
                Feedback { _ -> AnyPublisher<Event, Never> in
                    sutAInputEventStream.eraseToAnyPublisher()
                }
            }

            Transitions {
                From(MockStateA.self) {
                    On(MockNextEvent.self, transitionTo: MockStateB(value: randomValue))
                }
            }
        }
        .execute(on: DispatchQueue.immediateScheduler)

        let sutB = System {
            InitialState {
                MockStateA(value: 1)
            }

            Feedbacks {}
                .onEventEmitted { receivedEventB = $0 }

            Transitions {}
        }
        .execute(on: DispatchQueue.immediateScheduler)

        sutA.attach(to: sutB,
                    onSystemStateType: MockStateB.self,
                    emitAttachedSystemEvent: { mockStateB in
                        MockEventA(value: mockStateB.value)
                    })

        sutA.run()
        sutB.run()

        // when: making the state of the first system be MockStateB
        sutAInputEventStream.send(MockNextEvent())

        // Then: MockEventA is triggered in the attached System
        XCTAssertEqual(receivedEventB as? MockEventA, expectedEventB)
    }
}

private extension SystemTests {
    func assertStatesAreTheExpectedOnes(received: [State], expected: [State]) {
        XCTAssertEqual(received[0] as? MockStateA, expected[0] as? MockStateA)
        XCTAssertEqual(received[1] as? MockStateB, expected[1] as? MockStateB)
        XCTAssertEqual(received[2] as? MockStateC, expected[2] as? MockStateC)
        XCTAssertEqual(received[3] as? MockStateD, expected[3] as? MockStateD)
        XCTAssertEqual(received[4] as? MockStateA, expected[4] as? MockStateA)
        XCTAssertEqual(received[5] as? MockStateB, expected[5] as? MockStateB)
        XCTAssertEqual(received[6] as? MockStateC, expected[6] as? MockStateC)
        XCTAssertEqual(received[7] as? MockStateD, expected[7] as? MockStateD)
    }
}

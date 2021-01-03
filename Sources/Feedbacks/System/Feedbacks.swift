//
//  Feedbacks.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-28.
//

import Combine

public struct Feedbacks {
    let feedbacks: [Feedback]
    var onEventEmitted: ((Event) -> Void)?

    public init(@FeedbacksBuilder _ feedbacks: () -> [Feedback]) {
        self.feedbacks = feedbacks()
    }

    init(_ feedbacks: [Feedback], onEventEmitted: ((Event) -> Void)?) {
        self.feedbacks = feedbacks
        self.onEventEmitted = onEventEmitted
    }
}

extension Feedbacks {
    func eventStream(_ stateStream: AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> {
        let eventStreams = self.feedbacks.map { $0.sideEffect(stateStream.eraseToAnyPublisher()) }
        return Publishers.MergeMany(eventStreams).handleEvents(receiveOutput: self.onEventEmitted).eraseToAnyPublisher()
    }
}

extension Feedbacks {
    func add(feedback: Feedback) -> Feedbacks {
        Feedbacks(self.feedbacks + [feedback], onEventEmitted: self.onEventEmitted)
    }
}

// MARK: internal functions for Mediator
extension Feedbacks {
    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        filterMediatorValue: @escaping (MediatorType.Output) -> Bool,
        emitSystemEvent: @escaping (MediatorType.Output) -> Event
    ) -> Feedbacks where MediatorType.Failure == Never {
        let mediatorFeedback = Feedback { _ -> AnyPublisher<Event, Never> in
            mediator
                .filter(filterMediatorValue)
                .map(emitSystemEvent)
                .eraseToAnyPublisher()
        }

        return Feedbacks(self.feedbacks + [mediatorFeedback], onEventEmitted: self.onEventEmitted)
    }

    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        onMediatorValue: MediatorType.Output,
        emitSystemEvent: @escaping (MediatorType.Output) -> Event
    ) -> Feedbacks where MediatorType.Failure == Never, MediatorType.Output: Equatable {
        return self.attach(to: mediator,
                           filterMediatorValue: { mediatorValue -> Bool in
                            mediatorValue == onMediatorValue
                           },
                           emitSystemEvent: emitSystemEvent)
    }

    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        filterSystemState: @escaping (State) -> Bool,
        emitMediatorValue: @escaping (State) -> MediatorType.Output
    ) -> Feedbacks where MediatorType.Failure == Never {
        let mediatorFeedback = Feedback { (states: AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> in
            states
                .filter(filterSystemState)
                .handleEvents(receiveOutput: { state in
                    mediator.send(emitMediatorValue(state))
                })
                .flatMap { _ in Empty<Event, Never>().eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }

        return Feedbacks(self.feedbacks + [mediatorFeedback], onEventEmitted: self.onEventEmitted)
    }

    func attach<MediatorType: Mediator, StateType: State>(
        to mediator: MediatorType,
        onSystemStateType: StateType.Type,
        emitMediatorValue: @escaping (StateType) -> MediatorType.Output
    ) -> Feedbacks where MediatorType.Failure == Never {
        return self.attach(to: mediator) { state -> Bool in
            state is StateType
        } emitMediatorValue: { state in
            // force cast is acceptable here since a .filter() is applied to ensure the `state is StateType`. The use case is also
            // covered by unit tests.
            // swiftlint:disable force_cast
            emitMediatorValue(state as! StateType)
        }
    }

    func attach<MediatorType: Mediator, StateType: State>(
        to mediator: MediatorType,
        onSystemState: StateType,
        emitMediatorValue: @escaping (StateType) -> MediatorType.Output
    ) -> Feedbacks where MediatorType.Failure == Never, StateType: Equatable {
        return self.attach(to: mediator) { state -> Bool in
            (state as? StateType) == onSystemState
        } emitMediatorValue: { state in
            // force cast is acceptable here since a .filter() is applied to ensure the `state is StateType`. The use case is also
            // covered by unit tests.
            // swiftlint:disable force_cast
            emitMediatorValue(state as! StateType)
        }
    }
}

// MARK: modifiers
public extension Feedbacks {
    func execute<SchedulerType: Scheduler>(on scheduler: SchedulerType) -> Feedbacks {
        let scheduledSchedulers = self.feedbacks.map { $0.execute(on: scheduler) }
        return Feedbacks(scheduledSchedulers, onEventEmitted: self.onEventEmitted)
    }

    func onStateReceived(_ perform: @escaping (State) -> Void) -> Feedbacks {
        let stateReceivedFeedback = Feedback(strategy: .continueOnNewState) { (state: State) in
            perform(state)
            return Empty().eraseToAnyPublisher()
        }

        let newFeedbacks = self.feedbacks + [stateReceivedFeedback]

        return Feedbacks(newFeedbacks, onEventEmitted: self.onEventEmitted)
    }

    func onEventEmitted(_ perform: @escaping (Event) -> Void) -> Feedbacks {
        Feedbacks(self.feedbacks, onEventEmitted: perform)
    }
}

@_functionBuilder
public struct FeedbacksBuilder {
    public static func buildBlock(_ feedbacks: Feedback...) -> [Feedback] {
        feedbacks
    }
}

//
//  Feedbacks.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-28.
//

import Combine

/// Represents a series of Feedbacks to form a System
public struct Feedbacks {
    let feedbacks: [Feedback]
    var onEventEmitted: ((Event) -> Void)?

    /// - Parameter feedbacks: the individual feedbacks composing the System
    ///
    /// `Feedbacks {`
    ///     `Feedback(strategy: .continueOnNewState) { (state: LoadingState) in`
    ///          `...`
    ///          `Just(LoadedEvent()).eraseToAnyPublisher()`
    ///     `}`
    ///
    ///     `Feedback(strategy: .continueOnNewState) { (state: LoadingState) in`
    ///          `...`
    ///          `Just(ErrorEvent()).eraseToAnyPublisher()`
    ///     `}`
    /// `}`
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
        emitSystemEvent: @escaping (MediatorType.Output) -> Event?
    ) -> Feedbacks where MediatorType.Failure == Never {
        let mediatorFeedback = Feedback(mediator: mediator, emitSystemEvent: emitSystemEvent)
        return self.add(feedback: mediatorFeedback)
    }

    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        onMediatorValue: MediatorType.Output,
        emitSystemEvent: @escaping (MediatorType.Output) -> Event
    ) -> Feedbacks where MediatorType.Failure == Never, MediatorType.Output: Equatable {
        let mediatorFeedback = Feedback(mediator: mediator, onMediatorValue: onMediatorValue, emitSystemEvent: emitSystemEvent)
        return self.add(feedback: mediatorFeedback)
    }

    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        onMediatorValue: MediatorType.Output,
        emitSystemEvent: Event
    ) -> Feedbacks where MediatorType.Failure == Never, MediatorType.Output: Equatable {
        let mediatorFeedback = Feedback(mediator: mediator, onMediatorValue: onMediatorValue, emitSystemEvent: emitSystemEvent)
        return self.add(feedback: mediatorFeedback)
    }

    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        emitMediatorValue: @escaping (State) -> MediatorType.Output?
    ) -> Feedbacks where MediatorType.Failure == Never {
        let mediatorFeedback = Feedback(mediator: mediator, emitMediatorValue: emitMediatorValue)
        return self.add(feedback: mediatorFeedback)
    }

    func attach<MediatorType: Mediator, StateType: State>(
        to mediator: MediatorType,
        onSystemStateType: StateType.Type,
        emitMediatorValue: @escaping (StateType) -> MediatorType.Output
    ) -> Feedbacks where MediatorType.Failure == Never {
        let mediatorFeedback = Feedback(mediator: mediator, onSystemStateType: onSystemStateType, emitMediatorValue: emitMediatorValue)
        return self.add(feedback: mediatorFeedback)
    }

    func attach<MediatorType: Mediator, StateType: State>(
        to mediator: MediatorType,
        onSystemStateType: StateType.Type,
        emitMediatorValue: MediatorType.Output
    ) -> Feedbacks where MediatorType.Failure == Never {
        let mediatorFeedback = Feedback(mediator: mediator, onSystemStateType: onSystemStateType, emitMediatorValue: emitMediatorValue)
        return self.add(feedback: mediatorFeedback)
    }

    func attach<MediatorType: Mediator, StateType: State>(
        to mediator: MediatorType,
        onSystemState: StateType,
        emitMediatorValue: @escaping (StateType) -> MediatorType.Output
    ) -> Feedbacks where MediatorType.Failure == Never, StateType: Equatable {
        let mediatorFeedback = Feedback(mediator: mediator, onSystemState: onSystemState, emitMediatorValue: emitMediatorValue)
        return self.add(feedback: mediatorFeedback)
    }

    func attach<MediatorType: Mediator, StateType: State>(
        to mediator: MediatorType,
        onSystemState: StateType,
        emitMediatorValue: MediatorType.Output
    ) -> Feedbacks where MediatorType.Failure == Never, StateType: Equatable {
        let mediatorFeedback = Feedback(mediator: mediator, onSystemState: onSystemState, emitMediatorValue: emitMediatorValue)
        return self.add(feedback: mediatorFeedback)
    }
}

// MARK: modifiers
public extension Feedbacks {
    /// All the Feedbacks will be executed on the specified scheduler
    /// - Parameter scheduler: the scheduler on which to execute the feedbacks
    /// - Returns: a new Feedbacks, that executes the same side effects, but on the specified scheduler
    func execute<SchedulerType: Scheduler>(on scheduler: SchedulerType) -> Feedbacks {
        let scheduledSchedulers = self.feedbacks.map { $0.execute(on: scheduler) }
        return Feedbacks(scheduledSchedulers, onEventEmitted: self.onEventEmitted)
    }

    /// A middleware that is executed every time a new state is given as an input to all the Feedbacks
    /// - Parameter perform: the middleware to execute
    /// - Returns: the Feedbacks that executes the middleware before executing the side effects
    func onStateReceived(_ perform: @escaping (State) -> Void) -> Feedbacks {
        let stateReceivedFeedback = Feedback(strategy: .continueOnNewState) { (state: State) in
            perform(state)
            return Empty().eraseToAnyPublisher()
        }

        let newFeedbacks = self.feedbacks + [stateReceivedFeedback]

        return Feedbacks(newFeedbacks, onEventEmitted: self.onEventEmitted)
    }

    /// A middleware that is executed every time a new event is emitted by the Feedbacks
    /// - Parameter perform: the middleware to execute
    /// - Returns: the Feedbacks that executes the middleware after executing the side effects
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

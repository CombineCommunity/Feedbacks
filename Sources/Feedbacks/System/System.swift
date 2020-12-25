//
//  System.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-25.
//

import Combine
import Dispatch
import Foundation

public struct System {
    let initialState: InitialState
    let feedbacks: Feedbacks
    let stateMachine: StateMachine
    let scheduledStream: (AnyPublisher<Event, Never>) -> AnyPublisher<Event, Never>

    public init(@SystemBuilder _ system: () -> (InitialState, Feedbacks, StateMachine)) {
        let (initialState, feedbacks, stateMachine) = system()
        let defaultScheduler = DispatchQueue(label: "Feedbacks.System.\(UUID().uuidString)")
        let scheduledStream = { (events: AnyPublisher<Event, Never>) in
            events
                .subscribe(on: defaultScheduler)
                .receive(on: defaultScheduler)
                .eraseToAnyPublisher()
        }
        self.init(initialState: initialState, feedbacks: feedbacks, stateMachine: stateMachine, scheduledStream: scheduledStream)
    }

    init(initialState: InitialState,
         feedbacks: Feedbacks,
         stateMachine: StateMachine,
         scheduledStream: @escaping (AnyPublisher<Event, Never>) -> AnyPublisher<Event, Never>) {
        self.initialState = initialState
        self.feedbacks = feedbacks
        self.stateMachine = stateMachine
        self.scheduledStream = scheduledStream
    }
}

public extension System {
    var stream: AnyPublisher<State, Never> {
        Deferred<AnyPublisher<State, Never>> {
            let currentState = CurrentValueSubject<State, Never>(initialState.value)

            // merging all the effects into one event stream
            let stateInputStream = currentState.eraseToAnyPublisher()
            let eventStream = feedbacks.eventStream(stateInputStream)
            let scheduledEventStream = self.scheduledStream(eventStream)

            return scheduledEventStream
                .scan(initialState.value, stateMachine.reducer)
                .handleEvents(receiveOutput: currentState.send)
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

// MARK: modifiers
public extension System {
    func execute<SchedulerType: Scheduler>(on scheduler: SchedulerType) -> System {
        let scheduledStream: (AnyPublisher<Event, Never>) -> AnyPublisher<Event, Never> = { events in
            events
                .subscribe(on: scheduler)
                .receive(on: scheduler)
                .eraseToAnyPublisher()
        }
        return System(initialState: self.initialState,
                      feedbacks: self.feedbacks,
                      stateMachine: self.stateMachine,
                      scheduledStream: scheduledStream)
    }

    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        filterMediatorValue: @escaping (MediatorType.Output) -> Bool,
        emitSystemEvent: @escaping (MediatorType.Output) -> Event
    ) -> System where MediatorType.Failure == Never {
        let newFeedbacks = self.feedbacks.attach(to: mediator, filterMediatorValue: filterMediatorValue, emitSystemEvent: emitSystemEvent)

        return System(initialState: self.initialState,
                      feedbacks: newFeedbacks,
                      stateMachine: self.stateMachine,
                      scheduledStream: self.scheduledStream)
    }

    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        onMediatorValue: MediatorType.Output,
        emitSystemEvent: @escaping (MediatorType.Output) -> Event
    ) -> System where MediatorType.Failure == Never, MediatorType.Output: Equatable {
        let newFeedbacks = self.feedbacks.attach(to: mediator, onMediatorValue: onMediatorValue, emitSystemEvent: emitSystemEvent)

        return System(initialState: self.initialState,
                      feedbacks: newFeedbacks,
                      stateMachine: self.stateMachine,
                      scheduledStream: self.scheduledStream)
    }

    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        filterSystemState: @escaping (State) -> Bool,
        emitMediatorValue: @escaping (State) -> MediatorType.Output
    ) -> System where MediatorType.Failure == Never {
        let newFeedbacks = self.feedbacks.attach(to: mediator, filterSystemState: filterSystemState, emitMediatorValue: emitMediatorValue)

        return System(initialState: self.initialState,
                      feedbacks: newFeedbacks,
                      stateMachine: self.stateMachine,
                      scheduledStream: self.scheduledStream)
    }

    func attach<MediatorType: Mediator, StateType: State>(
        to mediator: MediatorType,
        onSystemStateType: StateType.Type,
        emitMediatorValue: @escaping (StateType) -> MediatorType.Output
    ) -> System where MediatorType.Failure == Never {
        let newFeedbacks = self.feedbacks.attach(to: mediator, onSystemStateType: onSystemStateType, emitMediatorValue: emitMediatorValue)

        return System(initialState: self.initialState,
                      feedbacks: newFeedbacks,
                      stateMachine: self.stateMachine,
                      scheduledStream: self.scheduledStream)
    }
    
    func attach<MediatorType: Mediator, StateType: State>(
        to mediator: MediatorType,
        onSystemState: StateType,
        emitMediatorValue: @escaping (StateType) -> MediatorType.Output
    ) -> System where MediatorType.Failure == Never, StateType: Equatable {
        let newFeedbacks = self.feedbacks.attach(to: mediator, onSystemState: onSystemState, emitMediatorValue: emitMediatorValue)

        return System(initialState: self.initialState,
                      feedbacks: newFeedbacks,
                      stateMachine: self.stateMachine,
                      scheduledStream: self.scheduledStream)
    }
}

@_functionBuilder
public struct SystemBuilder {
    public static func buildBlock(
        _ initialState: InitialState,
        _ feedbacks: Feedbacks,
        _ stateMachine: StateMachine
    ) -> (InitialState, Feedbacks, StateMachine) {
        (initialState, feedbacks, stateMachine)
    }
}

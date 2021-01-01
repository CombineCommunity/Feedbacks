//
//  System.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-25.
//

import Combine
import Dispatch
import Foundation

public class System {
    let initialState: InitialState
    var feedbacks: Feedbacks
    let stateMachine: StateMachine
    var scheduledStream: (AnyPublisher<Event, Never>) -> AnyPublisher<Event, Never>

    public convenience init(@SystemBuilder _ system: () -> (InitialState, Feedbacks, StateMachine)) {
        let (initialState, feedbacks, stateMachine) = System.decode(builder: system)
        self.init(initialState: initialState,
                  feedbacks: feedbacks,
                  stateMachine: stateMachine,
                  scheduler: DispatchQueue(label: "Feedbacks.System.\(UUID().uuidString)"))
    }

    init<SchedulerType: Scheduler>(initialState: InitialState,
                                   feedbacks: Feedbacks,
                                   stateMachine: StateMachine,
                                   scheduler: SchedulerType) {
        self.initialState = initialState
        self.feedbacks = feedbacks
        self.stateMachine = stateMachine
        self.scheduledStream = { (events: AnyPublisher<Event, Never>) in
            events
                .subscribe(on: scheduler)
                .receive(on: scheduler)
                .eraseToAnyPublisher()
        }
    }

    static func decode(builder system: () -> (InitialState, Feedbacks, StateMachine)) -> (InitialState, Feedbacks, StateMachine) {
        let (initialState, feedbacks, stateMachine) = system()
        return (initialState, feedbacks, stateMachine)
    }
}

public extension System {
    var stream: AnyPublisher<State, Never> {
        Deferred<AnyPublisher<State, Never>> { [initialState, feedbacks, stateMachine, scheduledStream] in
            let currentState = CurrentValueSubject<State, Never>(initialState.value)

            // merging all the effects into one event stream
            let stateInputStream = currentState.eraseToAnyPublisher()
            let eventStream = feedbacks.eventStream(stateInputStream)
            let scheduledEventStream = scheduledStream(eventStream)

            return scheduledEventStream
                .scan(initialState.value, stateMachine.reducer)
                .handleEvents(receiveOutput: currentState.send)
                .eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
}

// MARK: modifiers
public extension System {
    func execute<SchedulerType: Scheduler>(on scheduler: SchedulerType) -> Self {
        self.scheduledStream = { events in
            events
                .subscribe(on: scheduler)
                .receive(on: scheduler)
                .eraseToAnyPublisher()
        }

        return self
    }

    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        filterMediatorValue: @escaping (MediatorType.Output) -> Bool,
        emitSystemEvent: @escaping (MediatorType.Output) -> Event
    ) -> Self where MediatorType.Failure == Never {
        self.feedbacks = self.feedbacks.attach(to: mediator,
                                               filterMediatorValue:
                                                filterMediatorValue,
                                               emitSystemEvent: emitSystemEvent)
        return self
    }

    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        onMediatorValue: MediatorType.Output,
        emitSystemEvent: @escaping (MediatorType.Output) -> Event
    ) -> Self where MediatorType.Failure == Never, MediatorType.Output: Equatable {
        self.feedbacks = self.feedbacks.attach(to: mediator,
                                               onMediatorValue: onMediatorValue,
                                               emitSystemEvent: emitSystemEvent)
        return self
    }

    func attach<MediatorType: Mediator>(
        to mediator: MediatorType,
        filterSystemState: @escaping (State) -> Bool,
        emitMediatorValue: @escaping (State) -> MediatorType.Output
    ) -> Self where MediatorType.Failure == Never {
        self.feedbacks = self.feedbacks.attach(to: mediator,
                                               filterSystemState: filterSystemState,
                                               emitMediatorValue: emitMediatorValue)
        return self
    }

    func attach<MediatorType: Mediator, StateType: State>(
        to mediator: MediatorType,
        onSystemStateType: StateType.Type,
        emitMediatorValue: @escaping (StateType) -> MediatorType.Output
    ) -> Self where MediatorType.Failure == Never {
        self.feedbacks = self.feedbacks.attach(to: mediator,
                                               onSystemStateType: onSystemStateType,
                                               emitMediatorValue: emitMediatorValue)
        return self
    }

    func attach<MediatorType: Mediator, StateType: State>(
        to mediator: MediatorType,
        onSystemState: StateType,
        emitMediatorValue: @escaping (StateType) -> MediatorType.Output
    ) -> Self where MediatorType.Failure == Never, StateType: Equatable {
        self.feedbacks = self.feedbacks.attach(to: mediator,
                                               onSystemState: onSystemState,
                                               emitMediatorValue: emitMediatorValue)
        return self
    }

    func uiSystem<ViewState: State>(viewStateFactory: @escaping (State) -> ViewState) -> UISystem<ViewState> {
        UISystem(system: self, viewStateFactory: viewStateFactory)
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

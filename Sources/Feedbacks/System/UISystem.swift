//
//  UISystem.swift
//  
//
//  Created by Thibault Wittemberg on 2021-01-01.
//

import Combine
import Dispatch
import Foundation

public protocol CanBeUndefined {
    static var undefined: Self { get }
}

public class UISystem<ViewState: State & Equatable & CanBeUndefined>: System, ObservableObject {
    @Published public private(set) var state: ViewState
    let events = PassthroughSubject<Event, Never>()
    var scheduledViewStateFactoryStream: (AnyPublisher<State, Never>) -> AnyPublisher<State, Never>

    public convenience init(viewStateFactory: @escaping (State) -> ViewState,
                            @SystemBuilder _ system: () -> (InitialState, Feedbacks, StateMachine)) {
        let (initialState, feedbacks, stateMachine) = System.decode(builder: system)
        self.init(viewStateFactory: viewStateFactory,
                  initialState: initialState,
                  feedbacks: feedbacks,
                  stateMachine: stateMachine,
                  systemScheduler: DispatchQueue(label: "Feedbacks.System.\(UUID().uuidString)"),
                  viewStateScheduler: DispatchQueue(label: "Feedbacks.UISystem.\(UUID().uuidString)"))
    }

    public convenience init(system: System, viewStateFactory: @escaping (State) -> ViewState) {
        self.init(viewStateFactory: viewStateFactory,
                  initialState: system.initialState,
                  feedbacks: system.feedbacks,
                  stateMachine: system.stateMachine,
                  systemScheduler: DispatchQueue(label: "Feedbacks.System.\(UUID().uuidString)"),
                  viewStateScheduler: DispatchQueue(label: "Feedbacks.UISystem.\(UUID().uuidString)"))
    }

    // swiftlint:disable generic_type_name
    init<SchedulerType: Scheduler, ViewStateSchedulerType: Scheduler>(
        viewStateFactory: @escaping (State) -> ViewState,
        initialState: InitialState,
        feedbacks: Feedbacks,
        stateMachine: StateMachine,
        systemScheduler: SchedulerType,
        viewStateScheduler: ViewStateSchedulerType,
        extraStateRenderFunction: @escaping (State) -> Void = { _ in }
    ) {
        // since the initial view state is calculated asynchronously on the viewStateScheduler when the system is started
        // we set it to a initial undefined value
        self.state = ViewState.undefined
        self.scheduledViewStateFactoryStream = { states in
            states
                .receive(on: viewStateScheduler)
                .eraseToAnyPublisher()
        }

        super.init(initialState: initialState, feedbacks: feedbacks, stateMachine: stateMachine, scheduler: systemScheduler)

        let stateFeedback = Feedback { [weak self] (states: AnyPublisher<State, Never>) in
            guard let strongSelf = self else { return Empty().eraseToAnyPublisher() }

            return strongSelf
                .scheduledViewStateFactoryStream(states)
                .map(viewStateFactory)
                .filter { $0 != strongSelf.state }
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: { [weak self] in
                    extraStateRenderFunction($0)
                    self?.state = $0
                })
                .flatMap { _ in Empty<Event, Never>().eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }

        let eventFeedback = Feedback { [events] _ in
            events.eraseToAnyPublisher()
        }

        self.feedbacks = self.feedbacks.add(feedback: stateFeedback).add(feedback: eventFeedback)
    }

    public func emit(_ event: Event) {
        self.events.send(event)
    }
}

public extension UISystem {
    func executeViewStateFactory<SchedulerType: Scheduler>(on scheduler: SchedulerType) -> UISystem {
        self.scheduledViewStateFactoryStream = { states in
            states
                .receive(on: scheduler)
                .eraseToAnyPublisher()
        }

        return self
    }
}

#if canImport(SwiftUI)
import SwiftUI

public extension UISystem {
    func binding<Output>(keyPath: KeyPath<ViewState, Output>, emit: @escaping (Output) -> Event) -> Binding<Output> {
        Binding<Output> { [state] in
            state[keyPath: keyPath]
        } set: { [weak self] in
            self?.emit(emit($0))
        }
    }

    func binding<Output>(keyPath: KeyPath<ViewState, Output>, emit event: Event) -> Binding<Output> {
        self.binding(keyPath: keyPath, emit: { _ in event })
    }

    func binding<Output>(keyPath: KeyPath<ViewState, Output>) -> Binding<Output> {
        Binding<Output> { [state] in
            state[keyPath: keyPath]
        } set: { _ in
        }
    }
}
#endif

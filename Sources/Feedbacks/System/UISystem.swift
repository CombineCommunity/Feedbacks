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

/// A UISystem  is a decorator of a System. Its job is to add 2 UI feedbacks to the loop.
/// 1 - A Feedback where the received state is mapped to a ViewState and then sent to a published value (on the main thread) so that UI components can react to it
/// 2 - A Feedback the outputs a stream of user events
/// The published states of a UISystem will be distinct as the state side effect checks for equality before publishing.
public class UISystem<ViewState: State & Equatable & CanBeUndefined>: System, ObservableObject {
    @Published public private(set) var state: ViewState
    let events = PassthroughSubject<Event, Never>()
    var scheduledViewStateFactoryStream: (AnyPublisher<State, Never>) -> AnyPublisher<State, Never>

    /// Creates a UISystem based on the 3 components of a System (initial state, feedbacks, state machine) and a View State factory function
    /// - Parameters:
    ///   - viewStateFactory: the function to apply to each State produced by the System
    ///   - system: the 3 components of the System
    public convenience init(viewStateFactory: @escaping (State) -> ViewState,
                            @SystemBuilder _ system: () -> (InitialState, Feedbacks, Transitions)) {
        let (initialState, feedbacks, transitions) = System.decode(builder: system)
        self.init(viewStateFactory: viewStateFactory,
                  initialState: initialState,
                  feedbacks: feedbacks,
                  transitions: transitions,
                  systemScheduler: DispatchQueue(label: "Feedbacks.System.\(UUID().uuidString)"),
                  viewStateScheduler: DispatchQueue(label: "Feedbacks.UISystem.\(UUID().uuidString)"))
    }

    /// Creates a UISystem based on an existing System and a View State factory function
    /// - Parameters:
    ///   - system: the existing System
    ///   - viewStateFactory: the function to apply to each State produced by the System
    public convenience init(system: System, viewStateFactory: @escaping (State) -> ViewState) {
        self.init(viewStateFactory: viewStateFactory,
                  initialState: system.initialState,
                  feedbacks: system.feedbacks,
                  transitions: system.transitions,
                  systemScheduler: DispatchQueue(label: "Feedbacks.System.\(UUID().uuidString)"),
                  viewStateScheduler: DispatchQueue(label: "Feedbacks.UISystem.\(UUID().uuidString)"))
    }

    // swiftlint:disable generic_type_name
    init<SchedulerType: Scheduler, ViewStateSchedulerType: Scheduler>(
        viewStateFactory: @escaping (State) -> ViewState,
        initialState: InitialState,
        feedbacks: Feedbacks,
        transitions: Transitions,
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

        super.init(initialState: initialState, feedbacks: feedbacks, transitions: transitions, scheduler: systemScheduler)

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

    /// Emits an  Event in the System, in order to trigger a Transition
    /// - Parameter event: The event to emit
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

    /// Provides a binding on the System's View State
    /// - Parameters:
    ///   - keyPath: the path to the View State's property to expose as a Binding
    ///   - emit: the Event to emit when the binding is mutated
    /// - Returns: the binding on the View State
    func binding<Output>(keyPath: KeyPath<ViewState, Output>, emit: @escaping (Output) -> Event) -> Binding<Output> {
        Binding<Output> { [state] in
            state[keyPath: keyPath]
        } set: { [weak self] in
            self?.emit(emit($0))
        }
    }

    /// Provides a binding on the System's Vies State
    /// - Parameters:
    ///   - keyPath: the path to the View State's property to expose as a Binding
    ///   - event: the Event to emit when the binding is mutated
    /// - Returns: the binding on the View State
    func binding<Output>(keyPath: KeyPath<ViewState, Output>, emit event: Event) -> Binding<Output> {
        self.binding(keyPath: keyPath, emit: { _ in event })
    }

    /// Provides a read-only binding on the System's Vies State
    /// - Parameter keyPath: the path to the View State's property to expose as a Binding
    /// - Returns: the binding on the View State
    func binding<Output>(keyPath: KeyPath<ViewState, Output>) -> Binding<Output> {
        Binding<Output> { [state] in
            state[keyPath: keyPath]
        } set: { _ in
        }
    }
}
#endif

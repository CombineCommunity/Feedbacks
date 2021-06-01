//
//  UISystem.swift
//  
//
//  Created by Thibault Wittemberg on 2021-01-01.
//

import Combine
import Dispatch
import Foundation

/// A RawState encapsulates the System's state. Its only purpose is to  make the System's state compatible with
/// UISystem since UISystem is a generic class that awaits a concrete state to be published
public struct RawState: State {
    public let state: State
}

/// As a ViewState is computed on a background queue, the very first published state of a UISystem
/// is not known, waiting for the first ViewState to be calculated. A ViewState has to conform to this protocol
/// so it provides an undefined value
public protocol CanBeUndefined {
    static var undefined: Self { get }
}

/// A ViewState is a states that can be published by a UISystem. As it has to conform to
/// Equatable, the UISystem makes sure all ViewStates are distinct when it comes to published them.
public protocol ViewState: State, Equatable, CanBeUndefined {}

/// A UISystem  is a decorator of a System. Its job is to add 2 UI feedbacks to the loop.
/// 1 - A Feedback where the received state is mapped to a RawState or a ViewState and then sent to a published value so that UI components can react to it
/// 2 - A Feedback that outputs a stream of user events
/// The published states are always published on the main thread.
public class UISystem<PublishedState: State>: System, ObservableObject {
    @Published public private(set) var state: PublishedState
    public let events = PassthroughSubject<Event, Never>()

    /// Builds a UISystem based on its three components: an initial state, some feedbacks, a state machine
    /// The published state will be encapsulated inside a `RawState`.
    /// - Parameter components: the three components of the System
    public convenience init(@SystemBuilder _ components: () -> (InitialState, Feedbacks, Transitions)) where PublishedState == RawState {
        let (initialState, feedbacks, transitions) = System.decode(builder: components)

        self.init(initialState: initialState,
                  feedbacks: feedbacks,
                  transitions: transitions)
    }

    convenience init(system: System) where PublishedState == RawState {
        self.init(initialState: system.initialState,
                  feedbacks: system.feedbacks,
                  transitions: system.transitions)
    }

    override init(initialState: InitialState,
         feedbacks: Feedbacks,
         transitions: Transitions) where PublishedState == RawState {
        self.state = RawState(state: initialState.value)
        super.init(initialState: initialState,
                   feedbacks: feedbacks,
                   transitions: transitions)

        let stateFeedback = Self.makeStatePublishingFeedback(publishingFunction: { [weak self] in
            self?.state = $0
        })

        let eventFeedback = Feedback { [events] _ in
            events.eraseToAnyPublisher()
        }

        self.feedbacks = self.feedbacks
            .add(feedback: stateFeedback)
            .add(feedback: eventFeedback)
    }

    /// Creates a UISystem based on the 3 components of a System (initial state, feedbacks, state machine) and a View State factory function
    /// - Parameters:
    ///   - viewStateFactory: the function to apply to each State produced by the System
    ///   - system: the 3 components of the System
    public convenience init(
        viewStateFactory: @escaping (State) -> PublishedState,
        @SystemBuilder _ components: () -> (InitialState, Feedbacks, Transitions)
    ) where PublishedState: ViewState {
        self.init(viewStateFactory: viewStateFactory,
                  on: DispatchQueue(label: "Feedbacks.UISystem.\(UUID().uuidString)"),
                  components)
    }

    /// Creates a UISystem based on the 3 components of a System (initial state, feedbacks, state machine) and a View State factory function executed on the scheduler
    /// - Parameters:
    ///   - viewStateFactory: the function to apply to each State produced by the System
    ///   - on: the scheduler on which the viewStateFactory function will be executed
    ///   - system: the 3 components of the System
    public convenience init<SchedulerType: Scheduler>(
        viewStateFactory: @escaping (State) -> PublishedState,
        on scheduler: SchedulerType,
        @SystemBuilder _ components: () -> (InitialState, Feedbacks, Transitions)
    ) where PublishedState: ViewState {
        let (initialState, feedbacks, transitions) = System.decode(builder: components)

        self.init(viewStateFactory: viewStateFactory,
                  initialState: initialState,
                  feedbacks: feedbacks,
                  transitions: transitions,
                  viewStateScheduler: scheduler)
    }

    convenience init(system: System,
                     viewStateFactory: @escaping (State) -> PublishedState) where PublishedState: ViewState {
        self.init(system: system,
                  viewStateFactory: viewStateFactory,
                  on: DispatchQueue(label: "Feedbacks.UISystem.\(UUID().uuidString)"))
    }

    convenience init<SchedulerType: Scheduler>(system: System,
                                               viewStateFactory: @escaping (State) -> PublishedState,
                                               on scheduler: SchedulerType) where PublishedState: ViewState {
        self.init(viewStateFactory: viewStateFactory,
                  initialState: system.initialState,
                  feedbacks: system.feedbacks,
                  transitions: system.transitions,
                  viewStateScheduler: scheduler)
    }

    init<ViewStateSchedulerType: Scheduler> (
        viewStateFactory: @escaping (State) -> PublishedState,
        initialState: InitialState,
        feedbacks: Feedbacks,
        transitions: Transitions,
        viewStateScheduler: ViewStateSchedulerType
    ) where PublishedState: ViewState {
        // since the initial view state is calculated asynchronously on the viewStateScheduler when the system is started
        // we set it to a initial undefined value
        self.state = PublishedState.undefined

        super.init(initialState: initialState, feedbacks: feedbacks, transitions: transitions)

        let stateFeedback = Self.makeStatePublishingFeedback(
            viewStateFactory: viewStateFactory,
            on: viewStateScheduler,
            publishingFunction: { [weak self] viewState in
                self?.state = viewState
            }
        )

        let eventFeedback = Feedback { [events] _ in
            events.eraseToAnyPublisher()
        }

        self.feedbacks = self.feedbacks
            .add(feedback: stateFeedback)
            .add(feedback: eventFeedback)
    }

    /// Emits an event in the System
    /// - Parameter event: The event to emit
    public func emit(_ event: Event) {
        self.events.send(event)
    }

    static func makeStatePublishingFeedback(publishingFunction: @escaping (RawState) -> Void) -> Feedback
    where PublishedState == RawState {
        Feedback { states in
            return states
                .receive(on: DispatchQueue.main)
                .map { RawState(state: $0) }
                .handleEvents(receiveOutput: publishingFunction)
                .flatMap { _ in Empty<Event, Never>().eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }
    }

    static func makeStatePublishingFeedback<SchedulerType: Scheduler>(
        viewStateFactory: @escaping (State) -> PublishedState,
        on viewStateScheduler: SchedulerType,
        publishingFunction: @escaping (PublishedState) -> Void
    ) -> Feedback where PublishedState: ViewState {
        Feedback { states in
            return states
                .receive(on: viewStateScheduler)
                .map(viewStateFactory)
                .removeDuplicates()
                .receive(on: DispatchQueue.main)
                .handleEvents(receiveOutput: publishingFunction)
                .flatMap { _ in Empty<Event, Never>().eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }
    }
}

public extension System {
    /// Creates a UISystem based on the current System. It will add UI dedicated feedbacks so the user can interact with the System.
    /// The UISystem will publish a View State, based on the System's state and a View State factory function, executed on the specified scheduler
    /// - Parameters:
    ///   - viewStateFactory: the function to apply to each State produced by the System
    ///   - on: the scheduler on which the viewStateFactory function will be executed
    /// - Returns: The UISystem
    func uiSystem<ViewStateType: ViewState, SchedulerType: Scheduler>(
        viewStateFactory: @escaping (State) -> ViewStateType,
        on scheduler: SchedulerType) -> UISystem<ViewStateType> {
        UISystem(system: self, viewStateFactory: viewStateFactory, on: scheduler)
    }

    /// Creates a UISystem based on the current System. It will add UI dedicated feedbacks so the user can interact with the System.
    /// The UISystem will publish a View State, based on the System's state and a View State factory function, executed on a default scheduler
    /// - Parameters:
    ///   - viewStateFactory: the function to apply to each State produced by the System
    /// - Returns: The UISystem
    func uiSystem<ViewStateType: ViewState>(viewStateFactory: @escaping (State) -> ViewStateType) -> UISystem<ViewStateType> {
        UISystem(system: self, viewStateFactory: viewStateFactory)
    }

    /// Creates a UISystem based on the current System. It will add UI dedicated feedbacks so the user can interact with the System.
    /// The UISystem will publish a RawState, based on the System's state
    /// - Parameters:
    ///   - viewStateFactory: the function to apply to each State produced by the System
    /// - Returns: The UISystem
    func uiSystem() -> UISystem<RawState> {
        UISystem(system: self)
    }
}

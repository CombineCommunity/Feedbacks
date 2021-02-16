//
//  Feedback.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-25.
//

import Combine

/// A Feedback is the support for the execution of a side effect. A  System is composed
/// of several feedbacks. The purpose of a Feedback is to regulate an input state to make it converge
/// to a more stable value.
public struct Feedback {
    /// The ExecutionStrategy defines the behaviour of a Feedback when it is executed concurrently
    /// When cancelOnNewState, the feedback cancels the current side effect in favour of the new one
    /// When continueOnNewState, the feedback stacks the new side effect execution on the current one
    public enum Strategy {
        case cancelOnNewState
        case continueOnNewState

        func apply<StateType: State>(
            on sideEffect: @escaping (StateType) -> AnyPublisher<Event, Never>,
            willExecuteWithStrategy: @escaping (Feedback.Strategy) -> Void = { _ in }
        ) -> (AnyPublisher<StateType, Never>) -> AnyPublisher<Event, Never> {
            return { states in
                willExecuteWithStrategy(self)
                switch self {
                case .cancelOnNewState:
                    return states.map(sideEffect).switchToLatest().eraseToAnyPublisher()
                case .continueOnNewState:
                    return states.flatMap(sideEffect).eraseToAnyPublisher()
                }
            }
        }

        func apply(
            on sideEffect: @escaping (State) -> AnyPublisher<Event, Never>,
            willExecuteWithStrategy: @escaping (Feedback.Strategy) -> Void = { _ in }
        ) -> (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> {
            return { states in
                willExecuteWithStrategy(self)
                switch self {
                case .cancelOnNewState:
                    return states.map(sideEffect).switchToLatest().eraseToAnyPublisher()
                case .continueOnNewState:
                    return states.flatMap(sideEffect).eraseToAnyPublisher()
                }
            }
        }
    }

    let sideEffect: (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never>

    init(sideEffect: @escaping (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never>) {
        self.sideEffect = sideEffect
    }

    /// Creates a Feedback based on a side effect to execute
    /// - Parameters:
    ///   - on: The type of state that should trigger the side effect (forced to AnyState)
    ///   - sideEffect: the side effect to execute in the context of this feedback
    public init(on: AnyState.Type,
                sideEffect: @escaping (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never>) {
        self.init(sideEffect: sideEffect)
    }

    /// Creates a Feedback based on a side effect that takes a generic State as an input.
    /// - Parameters:
    ///   - on: The type of state that should trigger the side effect (forced to AnyState)
    ///   - strategy: when cancelOnNewState, the current side effect's execution will be canceled
    ///   - sideEffect: the side effect to execute in the context of the feedback
    /// - Returns: the feedback that stands for the side effect
    public init(on: AnyState.Type,
                strategy: Feedback.Strategy,
                willExecuteWithStrategy: @escaping (Feedback.Strategy) -> Void = { _ in },
                sideEffect: @escaping (State) -> AnyPublisher<Event, Never>) {
        self.init(on: AnyState.self, sideEffect: strategy.apply(on: sideEffect, willExecuteWithStrategy: willExecuteWithStrategy))
    }

    /// Creates a Feedback based on a side effect to execute
    /// - Parameters:
    ///   - on: The type of state that should trigger the side effect
    ///   - sideEffect: the side effect to execute in the context of this feedback
    public init<StateType: State>(on: StateType.Type,
                                  sideEffect: @escaping (AnyPublisher<StateType, Never>) -> AnyPublisher<Event, Never>) {
        let wrappingSideEffect: (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> = { states in
            sideEffect(states.compactMap { $0 as? StateType }.eraseToAnyPublisher())
        }
        self.sideEffect = wrappingSideEffect
    }

    /// Creates a Feedback based on a side effect that takes a generic State as an input.
    /// - Parameters:
    ///   - on: The type of state that should trigger the side effect
    ///   - strategy: when cancelOnNewState, the current side effect's execution will be canceled
    ///   - sideEffect: the side effect to execute in the context of the feedback
    /// - Returns: the feedback that stands for the side effect
    public init<StateType: State>(on: StateType.Type,
                strategy: Feedback.Strategy,
                willExecuteWithStrategy: @escaping (Feedback.Strategy) -> Void = { _ in },
                sideEffect: @escaping (StateType) -> AnyPublisher<Event, Never>) {
        self.init(on: StateType.self, sideEffect: strategy.apply(on: sideEffect, willExecuteWithStrategy: willExecuteWithStrategy))
    }
}

// MARK: internal functions for Mediator
extension Feedback {
    init<MediatorType: Mediator>(
        mediator: MediatorType,
        emitSystemEvent: @escaping (MediatorType.Output) -> Event?
    ) where MediatorType.Failure == Never {
        self.init { _ -> AnyPublisher<Event, Never> in
            mediator
                .compactMap(emitSystemEvent)
                .eraseToAnyPublisher()
        }
    }

    init<MediatorType: Mediator>(
        mediator: MediatorType,
        onMediatorValue: MediatorType.Output,
        emitSystemEvent: @escaping (MediatorType.Output) -> Event
    ) where MediatorType.Failure == Never, MediatorType.Output: Equatable {
        self.init(mediator: mediator,
                  emitSystemEvent: {
                    guard $0 == onMediatorValue else { return nil }
                    return emitSystemEvent($0)
                  })
    }

    init<MediatorType: Mediator>(
        mediator: MediatorType,
        onMediatorValue: MediatorType.Output,
        emitSystemEvent: Event
    ) where MediatorType.Failure == Never, MediatorType.Output: Equatable {
        self.init(mediator: mediator,
                  emitSystemEvent: {
                    guard $0 == onMediatorValue else { return nil }
                    return emitSystemEvent
                  })
    }

    init<MediatorType: Mediator>(
        mediator: MediatorType,
        emitMediatorValue: @escaping (State) -> MediatorType.Output?
    ) where MediatorType.Failure == Never {
        self.init { (states: AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> in
            states
                .handleEvents(receiveOutput: { state in
                    guard let mediatorEvent = emitMediatorValue(state) else { return }
                    mediator.send(mediatorEvent)
                })
                .flatMap { _ in Empty<Event, Never>().eraseToAnyPublisher() }
                .eraseToAnyPublisher()
        }
    }

    init<MediatorType: Mediator, StateType: State>(
        mediator: MediatorType,
        onSystemStateType: StateType.Type,
        emitMediatorValue: @escaping (StateType) -> MediatorType.Output
    ) where MediatorType.Failure == Never {
        self.init(mediator: mediator,
                  emitMediatorValue: { state in
                    guard let concreteState = state as? StateType else { return nil }
                    return emitMediatorValue(concreteState)
                  })
    }

    init<MediatorType: Mediator, StateType: State>(
        mediator: MediatorType,
        onSystemStateType: StateType.Type,
        emitMediatorValue: MediatorType.Output
    ) where MediatorType.Failure == Never {
        self.init(mediator: mediator,
                  emitMediatorValue: { state in
                    guard state is StateType else { return nil }
                    return emitMediatorValue
                  })
    }

    init<MediatorType: Mediator, StateType: State>(
        mediator: MediatorType,
        onSystemState: StateType,
        emitMediatorValue: @escaping (StateType) -> MediatorType.Output
    ) where MediatorType.Failure == Never, StateType: Equatable {
        self.init(mediator: mediator,
                  emitMediatorValue: { state in
                    guard
                        let concreteState = state as? StateType,
                        concreteState == onSystemState else { return nil }

                    return emitMediatorValue(concreteState)
                  })
    }

    init<MediatorType: Mediator, StateType: State>(
        mediator: MediatorType,
        onSystemState: StateType,
        emitMediatorValue: MediatorType.Output
    ) where MediatorType.Failure == Never, StateType: Equatable {
        self.init(mediator: mediator,
                  emitMediatorValue: { state in
                    guard
                        let concreteState = state as? StateType,
                        concreteState == onSystemState else { return nil }

                    return emitMediatorValue
                  })
    }
}

// MARK: modifiers
public extension Feedback {
    /// Creates an instance of this Feedback that will be executed on the specified scheduler
    /// - Parameter scheduler: the scheduler on which to execute the feedback
    /// - Returns: a new Feedback, that executes the same side effect, but on the specified scheduler
    func execute<SchedulerType: Scheduler>(on scheduler: SchedulerType) -> Feedback {
        let scheduledSideEffect: (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> = { states in
            self.sideEffect(states.receive(on: scheduler).eraseToAnyPublisher())
        }

        return Feedback(sideEffect: scheduledSideEffect)
    }

    /// Disables the Feedback while the `disabled` condition is true
    /// - Parameter disabled: return true to disable the transition
    /// - Returns: the Feedback that won't be executed until the `disabled` condition is false
    func disable(_ disabled: @escaping () -> Bool) -> Feedback {
        let conditionalSideEffect: (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> = { states in
            self.sideEffect(states.filter { _ in !disabled() }.eraseToAnyPublisher())
        }

        return Feedback(sideEffect: conditionalSideEffect)
    }

    /// A middleware that is executed every time a new state is given as an input to the Feedback
    /// - Parameter perform: the middleware to execute
    /// - Returns: the Feedback that executes the middleware before executing the side effect
    func onStateReceived(_ perform: @escaping (State) -> Void) -> Feedback {
        let performSideEffect: (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> = { states in
            self.sideEffect(states.handleEvents(receiveOutput: perform).eraseToAnyPublisher())
        }

        return Feedback(sideEffect: performSideEffect)
    }

    /// A middleware that is executed every time a new event is emitted by the Feedback
    /// - Parameter perform: the middleware to execute
    /// - Returns: the Feedback that executes the middleware after executing the side effect
    func onEventEmitted(_ perform: @escaping (Event) -> Void) -> Feedback {
        let performSideEffect: (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> = { states in
            self.sideEffect(states).handleEvents(receiveOutput: perform).eraseToAnyPublisher()
        }

        return Feedback(sideEffect: performSideEffect)
    }
}

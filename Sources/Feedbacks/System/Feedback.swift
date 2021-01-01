//
//  Feedback.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-25.
//

import Combine

public struct Feedback {
    public enum Strategy {
        case cancelOnNewState
        case continueOnNewState

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

    public init(sideEffect: @escaping (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never>) {
        self.sideEffect = sideEffect
    }

    public init(strategy: Feedback.Strategy,
                willExecuteWithStrategy: @escaping (Feedback.Strategy) -> Void = { _ in },
                sideEffect: @escaping (State) -> AnyPublisher<Event, Never>) {
        self.init(sideEffect: strategy.apply(on: sideEffect, willExecuteWithStrategy: willExecuteWithStrategy))
    }

    public init<StateType: State>(strategy: Feedback.Strategy,
                                  willExecuteWithStrategy: @escaping (Feedback.Strategy) -> Void = { _ in },
                                  sideEffect: @escaping (StateType) -> AnyPublisher<Event, Never>) {
        let wrappingSideEffect: (State) -> AnyPublisher<Event, Never> = { state in
            guard let concreteState = state as? StateType else { return Empty().eraseToAnyPublisher() }
            return sideEffect(concreteState)
        }

        self.init(strategy: strategy, willExecuteWithStrategy: willExecuteWithStrategy, sideEffect: wrappingSideEffect)
    }
}

// MARK: modifiers
public extension Feedback {
    func execute<SchedulerType: Scheduler>(on scheduler: SchedulerType) -> Feedback {
        let scheduledSideEffect: (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> = { states in
            self.sideEffect(states.receive(on: scheduler).eraseToAnyPublisher())
        }

        return Feedback(sideEffect: scheduledSideEffect)
    }

    func disable(_ disabled: @escaping () -> Bool) -> Feedback {
        let conditionalSideEffect: (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> = { states in
            self.sideEffect(states.filter { _ in !disabled() }.eraseToAnyPublisher())
        }

        return Feedback(sideEffect: conditionalSideEffect)
    }

    func onStateReceived(_ perform: @escaping (State) -> Void) -> Feedback {
        let performSideEffect: (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> = { states in
            self.sideEffect(states.handleEvents(receiveOutput: perform).eraseToAnyPublisher())
        }

        return Feedback(sideEffect: performSideEffect)
    }

    func onEventEmitted(_ perform: @escaping (Event) -> Void) -> Feedback {
        let performSideEffect: (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> = { states in
            self.sideEffect(states).handleEvents(receiveOutput: perform).eraseToAnyPublisher()
        }

        return Feedback(sideEffect: performSideEffect)
    }
}

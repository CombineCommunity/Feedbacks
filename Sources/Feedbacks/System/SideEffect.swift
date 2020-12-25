//
//  SideEffect.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-29.
//

import Combine

public enum SideEffect {}

// MARK: make for (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never>
public extension SideEffect {
    static func make<Arg>(
        _ sideEffect: @escaping (Arg, AnyPublisher<State, Never>) -> AnyPublisher<Event, Never>,
        arg: Arg
    ) -> (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg, futureState)
        }
    }

    static func make<Arg1, Arg2>(
        _ sideEffect: @escaping (Arg1, Arg2, AnyPublisher<State, Never>) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2
    ) -> (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, futureState)
        }
    }

    static func make<Arg1, Arg2, Arg3>(
        _ sideEffect: @escaping (Arg1, Arg2, Arg3, AnyPublisher<State, Never>) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2,
        arg3: Arg3
    ) -> (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, arg3, futureState)
        }
    }

    static func make<Arg1, Arg2, Arg3, Arg4>(
        _ sideEffect: @escaping (Arg1, Arg2, Arg3, Arg4, AnyPublisher<State, Never>) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2,
        arg3: Arg3,
        arg4: Arg4
    ) -> (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, arg3, arg4, futureState)
        }
    }

    static func make<Arg1, Arg2, Arg3, Arg4, Arg5>(
        _ sideEffect: @escaping (Arg1, Arg2, Arg3, Arg4, Arg5, AnyPublisher<State, Never>) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2,
        arg3: Arg3,
        arg4: Arg4,
        arg5: Arg5
    ) -> (AnyPublisher<State, Never>) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, arg3, arg4, arg5, futureState)
        }
    }
}

// MARK: make for (State) -> AnyPublisher<Event, Never>
public extension SideEffect {
    static func make<Arg>(
        _ sideEffect: @escaping (Arg, State) -> AnyPublisher<Event, Never>,
        arg: Arg
    ) -> (State) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg, futureState)
        }
    }

    static func make<Arg1, Arg2>(
        _ sideEffect: @escaping (Arg1, Arg2, State) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2
    ) -> (State) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, futureState)
        }
    }

    static func make<Arg1, Arg2, Arg3>(
        _ sideEffect: @escaping (Arg1, Arg2, Arg3, State) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2,
        arg3: Arg3
    ) -> (State) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, arg3, futureState)
        }
    }

    static func make<Arg1, Arg2, Arg3, Arg4>(
        _ sideEffect: @escaping (Arg1, Arg2, Arg3, Arg4, State) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2,
        arg3: Arg3,
        arg4: Arg4
    ) -> (State) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, arg3, arg4, futureState)
        }
    }

    static func make<Arg1, Arg2, Arg3, Arg4, Arg5>(
        _ sideEffect: @escaping (Arg1, Arg2, Arg3, Arg4, Arg5, State) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2,
        arg3: Arg3,
        arg4: Arg4,
        arg5: Arg5
    ) -> (State) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, arg3, arg4, arg5, futureState)
        }
    }
}

// MARK: make for (StateType) -> AnyPublisher<Event, Never>
public extension SideEffect {
    static func make<Arg, StateType: State>(
        _ sideEffect: @escaping (Arg, StateType) -> AnyPublisher<Event, Never>,
        arg: Arg
    ) -> (StateType) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg, futureState)
        }
    }

    static func make<Arg1, Arg2, StateType: State>(
        _ sideEffect: @escaping (Arg1, Arg2, StateType) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2
    ) -> (StateType) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, futureState)
        }
    }

    static func make<Arg1, Arg2, Arg3, StateType: State>(
        _ sideEffect: @escaping (Arg1, Arg2, Arg3, StateType) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2,
        arg3: Arg3
    ) -> (StateType) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, arg3, futureState)
        }
    }

    static func make<Arg1, Arg2, Arg3, Arg4, StateType: State>(
        _ sideEffect: @escaping (Arg1, Arg2, Arg3, Arg4, StateType) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2,
        arg3: Arg3,
        arg4: Arg4
    ) -> (StateType) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, arg3, arg4, futureState)
        }
    }

    static func make<Arg1, Arg2, Arg3, Arg4, Arg5, StateType: State>(
        _ sideEffect: @escaping (Arg1, Arg2, Arg3, Arg4, Arg5, StateType) -> AnyPublisher<Event, Never>,
        arg1: Arg1,
        arg2: Arg2,
        arg3: Arg3,
        arg4: Arg4,
        arg5: Arg5
    ) -> (StateType) -> AnyPublisher<Event, Never> {
        return { futureState in
            sideEffect(arg1, arg2, arg3, arg4, arg5, futureState)
        }
    }
}

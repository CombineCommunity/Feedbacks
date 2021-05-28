//
//  AnyState.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-21.
//

/// A wildcard state to describe a transition that should be executed whatever the state is for a specific event
///
/// `Transition(from: AnyState.self, on: LoadedEvent.self, then: LoadedState())`
///
public struct AnyState: State {}

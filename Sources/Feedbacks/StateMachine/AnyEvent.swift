//
//  AnyEvent.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-21.
//

/// A wildcard event to describe a transition that should be executed whatever the event is received for a specific state
///
/// `Transition(from: LoadingState.self, on: AnyEvent.self, then: NewState())`
///
public struct AnyEvent: Event {}

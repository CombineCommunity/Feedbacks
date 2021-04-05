//
//  AnyState.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-21.
//

/// A wildcard state to describe a transition that should be executed whatever the state is for a specific event
///
/// `From(AnyState.self) {
///     On(LoadedEvent.self, transitionTo: LoadedState())
/// }`
///
public struct AnyState: State, Instantiable {
    public static let instance = AnyState()
}

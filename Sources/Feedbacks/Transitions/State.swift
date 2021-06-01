//
//  State.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-21.
//

/// A protocol to be implemented by every state or view state in a System
/// As it is a StaticIdentifiable, it allows the concrete implementation to be statically identifiable when registered in a Transition
public protocol State: StaticIdentifiable {}

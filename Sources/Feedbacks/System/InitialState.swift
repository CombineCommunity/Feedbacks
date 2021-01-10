//
//  InitialState.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-29.
//

public struct InitialState {
    let value: State

    /// Create the initial state of System. This state will be given as an input of each Feedback once the System is started.
    /// - Parameter value: The value of the initial state.
    public init(_ value: () -> State) {
        self.value = value()
    }
}

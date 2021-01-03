//
//  InitialState.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-29.
//

public struct InitialState {
    let value: State

    public init(_ value: () -> State) {
        self.value = value()
    }
}

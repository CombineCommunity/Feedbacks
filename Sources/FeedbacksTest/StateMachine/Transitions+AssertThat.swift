//
//  Transitions+AssertThat.swift
//  
//
//  Created by Thibault Wittemberg on 2021-02-27.
//

import Feedbacks
import XCTest

public extension Transitions {
    func assertThat<OutputStateType: State & Equatable>(from state: State,
                                                        on event: Event,
                                                        newStateIs expectedState: OutputStateType) {
        let receivedState = self.reducer(state, event) as? OutputStateType
        XCTAssertEqual(receivedState, expectedState)
    }
    
    func assertThatStateIsUnchanged<InputStateType: State & Equatable>(from state: InputStateType,
                                                                       on event: Event) {
        let receivedState = self.reducer(state, event) as? InputStateType
        XCTAssertEqual(receivedState, state)
    }
}

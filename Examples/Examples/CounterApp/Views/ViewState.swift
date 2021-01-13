//
//  ViewState.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-12.
//

import Feedbacks
import Foundation
import struct SwiftUI.Color

extension CounterApp {
    enum ViewState {}
}

extension CounterApp.ViewState {
    enum Value: State, CanBeUndefined, Equatable, CustomStringConvertible {
        case displayUndefined
        case displayFixed(value: Int)
        case displayIncreasing(value: Int, paused: Bool)
        case displayDecreasing(value: Int, paused: Bool)

        static var undefined: CounterApp.ViewState.Value {
            CounterApp.ViewState.Value.displayUndefined
        }

        var description: String {
            switch self {
            case .displayFixed(let value):
                return "Fixed(value: \(value))"
            case .displayDecreasing(let value, let paused):
                return "Decreasing(value: \(value), paused: \(paused))"
            case .displayIncreasing(let value, let paused):
                return "Increasing(value: \(value), paused: \(paused))"
            case .displayUndefined:
                return "Undefined"
            }
        }

        var counterValue: Int {
            switch self {
            case let .displayFixed(value),
                 .displayDecreasing(let value, _),
                 .displayIncreasing(let value, _):
                return value
            case .displayUndefined:
                return 0
            }
        }

        var isCounterFixed: Bool {
            if case .displayFixed = self {
                return true
            }
            return false
        }

        var isCounterPaused: Bool {
            switch self {
            case .displayFixed:
                return true
            case .displayUndefined:
                return true
            case let .displayDecreasing(_, paused), let .displayIncreasing(_, paused):
                return paused
            }
        }

        var isCounterDecreasing: Bool {
            if case .displayDecreasing = self {
                return true
            }

            return false
        }

        var isCounterIncreasing: Bool {
            if case .displayIncreasing = self {
                return true
            }

            return false
        }

        var counterColor: Color {
            if self.isCounterFixed {
                return .green
            }

            if self.isCounterDecreasing {
                return .red
            }

            if self.isCounterIncreasing {
                return .blue
            }

            return .accentColor
        }
    }

    static func stateToViewState(state: State) -> CounterApp.ViewState.Value {
        switch state {
        case let fixed as CounterApp.States.Fixed: return CounterApp.ViewState.Value.displayFixed(value: fixed.value)
        case let decreasing as CounterApp.States.Decreasing: return CounterApp.ViewState.Value.displayDecreasing(value: decreasing.value,
                                                                                                                 paused: decreasing.isPaused)
        case let increasing as CounterApp.States.Increasing: return CounterApp.ViewState.Value.displayIncreasing(value: increasing.value,
                                                                                                                 paused: increasing.isPaused)
        default: return .undefined
        }
    }
}

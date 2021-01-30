//
//  UISystem+Binding.swift
//  
//
//  Created by Thibault Wittemberg on 2021-01-31.
//

#if canImport(SwiftUI)
import SwiftUI

public extension UISystem {
    /// Provides a read-only binding on the UISystem's published RawState
    /// - Parameter get: the function to read the RawState value
    /// - Returns: the binding on the published RawState
    func binding<Output>(get: @escaping (PublishedState) -> Output) -> Binding<Output> {
        Binding<Output> { [state] in
            get(state)
        } set: { _ in
        }
    }
}

public extension UISystem {
    /// Provides a binding on the UISystem's published RawState
    /// - Parameters:
    ///   - get: the function to read the RawState value
    ///   - emit: the function to emit an event in the System when the binding is mutated
    /// - Returns: the binding on the published RawState
    func binding<Output>(get: @escaping (PublishedState) -> Output, emit: @escaping (Output) -> Event) -> Binding<Output> {
        Binding<Output> { [state] in
            get(state)
        } set: { [weak self] in
            self?.emit(emit($0))
        }
    }

    /// Provides a binding on the System's RawState
    /// - Parameters:
    ///   - get: the function to read the RawState value
    ///   - event: the Event to emit when the binding is mutated
    /// - Returns: the binding on the ViewState
    func binding<Output>(get: @escaping (PublishedState) -> Output, emit event: Event) -> Binding<Output> {
        self.binding(get: get, emit: { _ in event })
    }
}

public extension UISystem where PublishedState: ViewState {
    /// Provides a binding on the System's published ViewState
    /// - Parameters:
    ///   - keyPath: the path to the ViewState's property to expose as a Binding
    ///   - emit: the Event to emit when the binding is mutated
    /// - Returns: the binding on the published ViewState
    func binding<Output>(keyPath: KeyPath<PublishedState, Output>, emit: @escaping (Output) -> Event) -> Binding<Output> {
        self.binding { viewState -> Output in
            viewState[keyPath: keyPath]
        } emit: {
            emit($0)
        }
    }

    /// Provides a binding on the System's published ViewState
    /// - Parameters:
    ///   - keyPath: the path to the View State's property to expose as a Binding
    ///   - event: the Event to emit when the binding is mutated
    /// - Returns: the binding on the published ViewState
    func binding<Output>(keyPath: KeyPath<PublishedState, Output>, emit event: Event) -> Binding<Output> {
        self.binding(keyPath: keyPath, emit: { _ in event })
    }

    /// Provides a read-only binding on the System's published ViewState
    /// - Parameter keyPath: the path to the View State's property to expose as a Binding
    /// - Returns: the binding on the published ViewState
    func binding<Output>(keyPath: KeyPath<PublishedState, Output>) -> Binding<Output> {
        self.binding { viewState -> Output in
            viewState[keyPath: keyPath]
        }
    }
}
#endif

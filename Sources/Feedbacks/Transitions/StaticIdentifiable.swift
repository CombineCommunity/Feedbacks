//
//  StaticIdentifiable.swift
//  
//
//  Created by Thibault Wittemberg on 2020-12-21.
//

/// Allows the concrete implementation to be statically identifiable when registered  in a Transition
public protocol StaticIdentifiable {
    static var id: AnyHashable { get }
}

public extension StaticIdentifiable {
    static var id: AnyHashable {
        String(reflecting: Self.self)
    }

    var instanceId: AnyHashable {
        Self.id
    }
}

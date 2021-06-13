//
//  Instantiable.swift
//  
//
//  Created by Thibault Wittemberg on 2021-06-12.
//

/// A protocol to be implemented by every data type that offer the ability to provide a default instance
/// This can be used to describe a System and to automatically generate documentation
public protocol Instantiable {
    static var instance: Self { get }
}

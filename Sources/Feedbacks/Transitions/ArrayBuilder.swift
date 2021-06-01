//
//  ArrayBuilder.swift
//  
//
//  Created by Thibault Wittemberg on 2021-02-21.
//

@_functionBuilder
public struct ArrayBuilder<Value> {
    public static func buildBlock(_ values: Value...) -> [Value] {
        values
    }
}

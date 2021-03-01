//
//  Counter.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-02-28.
//

struct Counter: Equatable {
    let value: Int
    let min: Int
    let max: Int

    func decrease() -> Counter {
        Counter(value: self.value - 1, min: self.min, max: self.max)
    }

    func increase() -> Counter {
        Counter(value: self.value + 1, min: self.min, max: self.max)
    }
}

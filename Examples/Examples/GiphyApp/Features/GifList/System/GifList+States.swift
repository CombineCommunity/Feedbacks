//
//  GifList+States.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

import Feedbacks

// define a namespace for the GifList states
extension GifList {
    enum States {}
}

extension GifList.States {
    struct Loading: State, Equatable {
        var page: Int = 0
    }

    struct Loaded: State, Equatable {
        static func == (lhs: GifList.States.Loaded, rhs: GifList.States.Loaded) -> Bool {
            return
                lhs.currentPage == rhs.currentPage &&
                lhs.totalPage == rhs.totalPage &&
                lhs.gifs.map { $0.0 } == rhs.gifs.map { $0.0 } &&
                lhs.gifs.map { $0.1 } == rhs.gifs.map { $0.1 }
        }

        let gifs: [(GifOverview, Bool)]
        let currentPage: Int
        let totalPage: Int
    }

    struct Failed: State, Equatable {}
}

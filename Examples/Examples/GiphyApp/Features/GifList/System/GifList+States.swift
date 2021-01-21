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
    struct Loading: State {
        var page: Int = 0
    }

    struct Loaded: State {
        let gifs: [(GifOverview, Bool)]
        let currentPage: Int
        let totalPage: Int
    }

    struct Failed: State {}
}

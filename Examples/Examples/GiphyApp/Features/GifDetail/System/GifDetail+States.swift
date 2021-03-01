//
//  GifDetail+States.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-17.
//

import Feedbacks

extension GifDetail {
    enum States {}
}

extension GifDetail.States {
    struct Loading: State, Equatable {}

    struct Loaded: State, Equatable {
        let gif: Gif
        let isFavorite: Bool
    }

    struct TogglingFavorite: State, Equatable {
        let gif: Gif
        let isFavorite: Bool
    }

    struct Failed: State, Equatable {}
}

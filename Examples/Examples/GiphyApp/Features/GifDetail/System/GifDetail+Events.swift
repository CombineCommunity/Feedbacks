//
//  GifDetail+Events.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-17.
//

import Feedbacks

extension GifDetail {
    enum Events {}
}

extension GifDetail.Events {
    struct LoadingIsComplete: Event {
        let gif: Gif
        let isFavorite: Bool
    }

    struct LoadingHasFailed: Event {}

    struct ToggleFavorite: Event {}
}

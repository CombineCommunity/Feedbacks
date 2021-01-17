//
//  GifList+Events.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

import Feedbacks

// define a namespace for the GifList events
extension GifList {
    enum Events {}
}

extension GifList.Events {
    struct LoadPrevious: Event {}

    struct LoadNext: Event {}

    struct LoadingIsComplete: Event {
        let gifs: [(GifOverview, Bool)]
        let currentPage: Int
        let totalPage: Int
    }

    struct LoadingHasFailed: Event {}

    struct Refresh: Event {}
}

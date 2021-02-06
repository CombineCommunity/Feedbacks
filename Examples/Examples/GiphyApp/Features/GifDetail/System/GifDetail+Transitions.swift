//
//  GifDetail+Transitions.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-17.
//

import Feedbacks

extension GifDetail {
    enum Transitions {}
}

extension GifDetail.Transitions {
    static let loadingTransitions = Transitions {
        Transition(from: GifDetail.States.Loading.self, on: GifDetail.Events.LoadingIsComplete.self) { _, event in
            GifDetail.States.Loaded(gif: event.gif, isFavorite: event.isFavorite)
        }

        Transition(from: GifDetail.States.Loading.self, on: GifDetail.Events.LoadingHasFailed.self, then: GifDetail.States.Failed())
    }

    static let loadedTransition = Transition(from: GifDetail.States.Loaded.self,
                                             on: GifDetail.Events.ToggleFavorite.self) { state, _ in
        GifDetail.States.TogglingFavorite(gif: state.gif, isFavorite: !state.isFavorite)
    }

    static let togglingTransitions = Transitions {
        Transition(from: GifDetail.States.TogglingFavorite.self, on: GifDetail.Events.LoadingIsComplete.self) { _, event in
            GifDetail.States.Loaded(gif: event.gif, isFavorite: event.isFavorite)
        }

        Transition(from: GifDetail.States.TogglingFavorite.self, on: GifDetail.Events.LoadingHasFailed.self, then: GifDetail.States.Failed())
    }
}

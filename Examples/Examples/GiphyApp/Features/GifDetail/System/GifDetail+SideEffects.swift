//
//  GifDetail+SideEffects.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-17.
//

import Combine
import Feedbacks

extension GifDetail {
    enum SideEffects {}
}

extension GifDetail.SideEffects {
    static func load(loadGifFunction: () -> AnyPublisher<Gif, Swift.Error>,
                     isFavoriteFunction: @escaping (Gif) -> Bool,
                     state: GifDetail.States.Loading) -> AnyPublisher<Event, Never> {
        return loadGifFunction()
            .map { gif in
                let isFavorite = isFavoriteFunction(gif)
                return (gif, isFavorite)
            }
            .map {
                GifDetail.Events.LoadingIsComplete(gif: $0, isFavorite: $1)
            }
            .replaceError(with: GifDetail.Events.LoadingHasFailed())
            .eraseToAnyPublisher()
    }

    static func toggleFavorite(saveFavoriteFunction: (Gif, Bool) -> AnyPublisher<Void, Swift.Error>,
                               state: GifDetail.States.TogglingFavorite) -> AnyPublisher<Event, Never> {
        return saveFavoriteFunction(state.gif, state.isFavorite)
            .map {
                GifDetail.Events.LoadingIsComplete(gif: state.gif, isFavorite: state.isFavorite)
            }
            .replaceError(with: GifDetail.Events.LoadingHasFailed())
            .eraseToAnyPublisher()
    }
}

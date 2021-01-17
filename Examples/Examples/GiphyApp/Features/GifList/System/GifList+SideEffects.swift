//
//  GifList+SideEffects.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

import Combine
import Feedbacks

// define a namespace for the GifList side effects
extension GifList {
    enum SideEffects {}
}

extension GifList.SideEffects {
    // This side effect reacts to the "Loading" state.
    // Its goals is to load a page of Gifs, and for each Gif determine if it is in the list of favorite.
    // Once done, the side effect will output a LoadingIsComplete event, or a LoadingHasFailed in case of some error
    static func load(loadPageFunction: (Int) -> AnyPublisher<([GifOverview], Int), Swift.Error>,
                     isFavoriteFunction: @escaping (GifOverview) -> Bool,
                     state: GifList.States.Loading) -> AnyPublisher<Event, Never> {

        return loadPageFunction(state.page)
            .map { gifOverviews, totalPage in
                let gifsWithFavorite = gifOverviews.map { ($0, isFavoriteFunction($0)) }
                return (gifsWithFavorite, totalPage)
            }
            .map { gifsWithFavorite, totalPage in
                GifList.Events.LoadingIsComplete(gifs: gifsWithFavorite,
                                                 currentPage: state.page,
                                                 totalPage: totalPage)
            }
            .handleEvents(receiveCompletion: { print("load completion: \($0)") })
            .replaceError(with: GifList.Events.LoadingHasFailed())
            .eraseToAnyPublisher()
    }
}

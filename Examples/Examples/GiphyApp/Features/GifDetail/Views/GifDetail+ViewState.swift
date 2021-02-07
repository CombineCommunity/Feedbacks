//
//  GifDetail+ViewState.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-19.
//

import Feedbacks

extension GifDetail {
    enum ViewState {}
}

extension GifDetail.ViewState {
    enum Value: ViewState {
        case displayLoading
        case displayLoaded(item: GifDetail.ViewState.Item)
        case displayTogglingFavorite(item: GifDetail.ViewState.Item)
        case displayError

        static let undefined: GifDetail.ViewState.Value = .displayLoading
    }

    struct Item: Equatable {
        let title: String
        let type: String
        let rating: String
        let user: String
        let favorite: String
        let videoUrl: String
    }

    static func stateToViewState(state: State) -> GifDetail.ViewState.Value {
        switch state {
        case is GifDetail.States.Loading: return GifDetail.ViewState.Value.displayLoading
        case let loaded as GifDetail.States.Loaded: return GifDetail.ViewState.Value.displayLoaded(
            item: Item(title: loaded.gif.title,
                       type: loaded.gif.type,
                       rating: loaded.gif.rating,
                       user: loaded.gif.username,
                       favorite: loaded.isFavorite ? "star.fill" : "star",
                       videoUrl: loaded.gif.images.fixedHeightData.mp4)
        )
        case let toggling as GifDetail.States.TogglingFavorite: return GifDetail.ViewState.Value.displayTogglingFavorite(
            item: Item(title: toggling.gif.title,
                       type: toggling.gif.type,
                       rating: toggling.gif.rating,
                       user: toggling.gif.username,
                       favorite: toggling.isFavorite ? "star.fill" : "star",
                       videoUrl: toggling.gif.images.fixedHeightData.mp4)
        )
        case is GifDetail.States.Failed: return GifDetail.ViewState.Value.displayError
        default: return .undefined
        }
    }
}

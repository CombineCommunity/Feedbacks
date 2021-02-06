//
//  Gif+System.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-17.
//

import Combine
import Feedbacks
import Foundation

extension GifDetail {
    enum System {}
}

extension GifDetail.System {
    static func make(id: String) -> System {

        let loadSideEffect = SideEffect.make(GifDetail.SideEffects.load(loadGifFunction:isFavoriteFunction:state:),
                                             arg1: { GifDetail.Dependencies.loadGif(id: id) },
                                             arg2: GifDetail.Dependencies.isFavorite(gif:))



        let toggleFavoriteSideEffect = SideEffect.make(GifDetail.SideEffects.toggleFavorite(saveFavoriteFunction:state:),
                                                       arg: GifDetail.Dependencies.saveFavorite(gif:isFavorite:))

        return System {
            InitialState {
                GifDetail.States.Loading()
            }

            Feedbacks {
                Feedback(strategy: .cancelOnNewState, sideEffect: loadSideEffect)
                    .execute(on: DispatchQueue(label: "Load Gif Queue"))

                Feedback(strategy: .cancelOnNewState, sideEffect: toggleFavoriteSideEffect)
                    .execute(on: DispatchQueue(label: "Toggle Favorite Queue"))
            }
            .onStateReceived {
                print("GifDetail: New state has been received: \($0)")
            }
            .onEventEmitted {
                print("GifDetail: New event has been triggered: \($0)")
            }

            Transitions {
                GifDetail.Transitions.loadingTransitions
                GifDetail.Transitions.loadedTransition
                GifDetail.Transitions.togglingTransitions
            }
        }
    }
}

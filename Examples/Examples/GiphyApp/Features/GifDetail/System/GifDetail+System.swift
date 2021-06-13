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
                Feedback(on: GifDetail.States.Loading.self, strategy: .cancelOnNewState, perform: loadSideEffect)
                Feedback(on: GifDetail.States.TogglingFavorite.self, strategy: .cancelOnNewState, perform: toggleFavoriteSideEffect)
            }
            .onStateReceived {
                print("GifDetail: New state has been received: \($0)")
            }
            .onEventEmitted {
                print("GifDetail: New event has been triggered: \($0)")
            }

            Transitions {
                From(GifDetail.States.Loading.self) {
                    On(GifDetail.Events.LoadingIsComplete.self, transitionTo: GifDetail.States.Loaded.self) { event in
                        .init(gif: event.gif, isFavorite: event.isFavorite)
                    }

                    On(GifDetail.Events.LoadingHasFailed.self, transitionTo: GifDetail.States.Failed())
                }

                From(GifDetail.States.Loaded.self) { state in
                    On(GifDetail.Events.ToggleFavorite.self, transitionTo: GifDetail.States.TogglingFavorite(gif: state.gif, isFavorite: !state.isFavorite))
                }

                From(GifDetail.States.TogglingFavorite.self) {
                    On(GifDetail.Events.LoadingIsComplete.self, transitionTo: GifDetail.States.Loaded.self) { event in
                        .init(gif: event.gif, isFavorite: event.isFavorite)
                    }
                    On(GifDetail.Events.LoadingHasFailed.self, transitionTo: GifDetail.States.Failed())
                }
            }
        }.execute(on: DispatchQueue(label: "Load Gif Queue"))
    }
}

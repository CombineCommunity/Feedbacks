//
//  GifList+System.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

import Combine
import Feedbacks
import Foundation

extension GifList {
    enum System {}
}

extension GifList.System {
    static var gifOverview : System  {
        let loadSideEffect = SideEffect.make(GifList.SideEffects.load(loadPageFunction:isFavoriteFunction:state:),
                                             arg1: GifList.Dependencies.loadPage(page:),
                                             arg2: GifList.Dependencies.isFavorite(gifOverview:))

        return System {
            InitialState {
                GifList.States.Loading()
            }

            Feedbacks {
                Feedback(on: GifList.States.Loading.self , strategy: .cancelOnNewState, sideEffect: loadSideEffect)
                    .execute(on: DispatchQueue(label: "Load Gifs Queue"))
            }
            .onStateReceived {
                print("GifList: New state has been received: \($0)")
            }
            .onEventEmitted {
                print("GifList: New event has been triggered: \($0)")
            }

            Transitions {
                GifList.Transitions.loadingTransitions
                GifList.Transitions.loadedTransitions
                GifList.Transitions.failedTransition
            }
        }
    }
}

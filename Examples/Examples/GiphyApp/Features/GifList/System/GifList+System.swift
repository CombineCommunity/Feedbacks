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
    static var gifs : System  {
        let loadSideEffect = SideEffect.make(GifList.SideEffects.load(loadPageFunction:isFavoriteFunction:state:),
                                             arg1: GifList.Dependencies.loadPage(page:),
                                             arg2: GifList.Dependencies.isFavorite(gifOverview:))

        return System {
            InitialState {
                GifList.States.Loading()
            }

            Feedbacks {
                Feedback(on: GifList.States.Loading.self , strategy: .cancelOnNewState, perform: loadSideEffect)
            }
            .onStateReceived {
                print("GifList: New state has been received: \($0)")
            }
            .onEventEmitted {
                print("GifList: New event has been triggered: \($0)")
            }

            Transitions {
                From(GifList.States.Loading.self) {
                    On(GifList.Events.LoadingIsComplete.self, transitionTo: GifList.States.Loaded.self) { event in
                        .init(gifs: event.gifs, currentPage: event.currentPage, totalPage: event.totalPage)
                    }

                    On(GifList.Events.LoadingHasFailed.self, transitionTo: GifList.States.Failed())
                }

                From(GifList.States.Loaded.self) { state in
                    On(GifList.Events.Refresh.self, transitionTo: GifList.States.Loading(page: state.currentPage))

                    On(GifList.Events.LoadPrevious.self, transitionTo: GifList.States.Loading.self) {
                        let previousPage = state.currentPage - 1
                        return .init(page: previousPage > 0 ? previousPage : 0)
                    }

                    On(GifList.Events.LoadNext.self, transitionTo: GifList.States.Loading.self) {
                        let nextPage = state.currentPage + 1
                        return .init(page: nextPage < state.totalPage ? nextPage : state.totalPage)
                    }
                }

                From(GifList.States.Failed.self) {
                    On(GifList.Events.Refresh.self, transitionTo: GifList.States.Loading())
                }
            }
        }.execute(on: DispatchQueue(label: "Load Gifs Queue"))
    }
}

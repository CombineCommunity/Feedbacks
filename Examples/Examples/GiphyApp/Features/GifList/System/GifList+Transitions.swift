//
//  GifList+Transitions.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

import Feedbacks

// define a namespace for the GifList transitions
extension GifList {
    enum Transitions {}
}

extension GifList.Transitions {
    static let loadingTransitions = Transitions {
        Transition(from: GifList.States.Loading.self, on: GifList.Events.LoadingIsComplete.self) { _, event -> State in
            GifList.States.Loaded(gifs: event.gifs,
                                  currentPage: event.currentPage,
                                  totalPage: event.totalPage)
        }

        Transition(from: GifList.States.Loading.self, on: GifList.Events.LoadingHasFailed.self, then: GifList.States.Failed())
    }

    static let loadedTransitions = Transitions {
        Transition(from: GifList.States.Loaded.self, on: GifList.Events.Refresh.self) { state, _ -> State in
            GifList.States.Loading(page: state.currentPage)
        }

        Transition(from: GifList.States.Loaded.self, on: GifList.Events.LoadPrevious.self) { state, _ -> State in
            let previousPage = state.currentPage - 1
            return GifList.States.Loading(page: previousPage > 0 ? previousPage : 0)
        }

        Transition(from: GifList.States.Loaded.self, on: GifList.Events.LoadNext.self) { state, _ -> State in
            let nextPage = state.currentPage + 1
            return GifList.States.Loading(page: nextPage < state.totalPage ? nextPage : state.totalPage)
        }
    }

    static let failedTransitions = Transitions {
        Transition(from: GifList.States.Failed.self, on: GifList.Events.Refresh.self, then: GifList.States.Loading())
    }
}

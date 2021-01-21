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
        let loadGifFunction: () -> AnyPublisher<Gif, Swift.Error> = {
            let apiKey = "f4HXQOslkXuDXgFlZQATpWXc8FtjhuUR"
            let baseUrl = "api.giphy.com"
            let parameter = GifDetailRequestParameter(apiKey: apiKey)
            guard let urlRequest = HTTPService.makeURLEncodedRequest(method: "GET",
                                                                     baseUrl: baseUrl,
                                                                     path: "/v1/gifs/\(id)",
                                                                     parameter: parameter) else {
                return Fail(error: HTTPService.HTTPError()).eraseToAnyPublisher()
            }

            return HTTPService
                .fetch(request: urlRequest)
                .map { (response: GifDetailResponse) in
                    response.data
                }
                .eraseToAnyPublisher()
        }

        let isFavoriteFunction: (Gif) -> Bool = { gif in
            StorageService.instance.load(key: gif.id) ?? false
        }

        let loadSideEffect = SideEffect.make(GifDetail.SideEffects.load(loadGifFunction:isFavoriteFunction:state:),
                                             arg1: loadGifFunction,
                                             arg2: isFavoriteFunction)

        let saveFavoriteFunction: (Gif, Bool) -> AnyPublisher<Void, Swift.Error> = { gif, isFavorite in
            return Future { subscriber in
                StorageService.instance.store(key: gif.id, value: isFavorite)
                subscriber(.success(()))
            }.eraseToAnyPublisher()
        }

        let toggleFavoriteSideEffect = SideEffect.make(GifDetail.SideEffects.toggleFavorite(saveFavoriteFunction:state:),
                                                       arg: saveFavoriteFunction)

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
                GifDetail.Transitions.loadedTransitions
                GifDetail.Transitions.togglingTransitions
            }
        }
    }
}

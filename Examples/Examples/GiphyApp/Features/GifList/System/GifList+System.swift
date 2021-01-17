//
//  GifList+System.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

import Combine
import Feedbacks

extension GifList {
    enum System {}
}

extension GifList.System {
    static func make() -> System  {
        let loadPageFunction: (Int) -> AnyPublisher<([GifOverview], Int), Swift.Error> = { page in
            let apiKey = "f4HXQOslkXuDXgFlZQATpWXc8FtjhuUR"
            let baseUrl = "api.giphy.com"
            let pageSize = 10

            let parameter = GifListRequestParameter(apiKey: apiKey, limit: pageSize, offset: pageSize * page)
            guard let urlRequest = HTTPService.makeURLEncodedRequest(method: "GET",
                                                                     baseUrl: baseUrl, path: "/v1/gifs/trending",
                                                                     parameter: parameter) else {
                return Fail(error: HTTPService.HTTPError()).eraseToAnyPublisher()
            }

            return HTTPService
                .fetch(request: urlRequest)
                .map { (response: GifListResponse) in
                    let gifOverviews = response.data
                    let pagination = response.pagination

                    let factor = pagination.totalCount % pageSize
                    let numberOfPages = factor == 0 ? (pagination.totalCount / pageSize) : (pagination.totalCount / pageSize) + 1
                    return (gifOverviews, numberOfPages)
                }
                .eraseToAnyPublisher()
        }

        let isFavoriteFunction: (GifOverview) -> Bool = { gifOverview in
            StorageService.instance.load(key: gifOverview.id) ?? false
        }

        let loadSideEffect = SideEffect.make(GifList.SideEffects.load(loadPageFunction:isFavoriteFunction:state:),
                                             arg1: loadPageFunction,
                                             arg2: isFavoriteFunction)

        return System {
            InitialState {
                GifList.States.Loading()
            }

            Feedbacks {
                Feedback(strategy: .cancelOnNewState, sideEffect: loadSideEffect)
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
                GifList.Transitions.failedTransitions
            }
        }
    }
}

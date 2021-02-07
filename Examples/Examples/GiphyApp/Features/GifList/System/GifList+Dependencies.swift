//
//  GifList+Dependencies.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-02-06.
//

import Combine

extension GifList {
    enum Dependencies {}
}

extension GifList.Dependencies {
    static func loadPage(page: Int) -> AnyPublisher<([GifOverview], Int), Swift.Error> {
        let apiKey = "f4HXQOslkXuDXgFlZQATpWXc8FtjhuUR"
        let baseUrl = "api.giphy.com"
        let pageSize = 10

        let parameter = GifListRequestParameter(apiKey: apiKey, limit: pageSize, offset: pageSize * page)
        guard let urlRequest = HTTPService.makeURLEncodedRequest(method: "GET",
                                                                 baseUrl: baseUrl,
                                                                 path: "/v1/gifs/trending",
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

    static func isFavorite(gifOverview: GifOverview) -> Bool {
        StorageService.instance.load(key: gifOverview.id) ?? false
    }
}

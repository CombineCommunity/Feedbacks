//
//  GifDetail+Dependencies.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-02-06.
//

import Combine

extension GifDetail {
    enum Dependencies {}
}

extension GifDetail.Dependencies {
    static func loadGif(id: String) -> AnyPublisher<Gif, Swift.Error> {
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

    static func isFavorite(gif: Gif) -> Bool {
        StorageService.instance.load(key: gif.id) ?? false
    }

    static func saveFavorite(gif: Gif, isFavorite: Bool) -> AnyPublisher<Void, Swift.Error> {
        return Future { subscriber in
            StorageService.instance.store(key: gif.id, value: isFavorite)
            subscriber(.success(()))
        }.eraseToAnyPublisher()
    }
}

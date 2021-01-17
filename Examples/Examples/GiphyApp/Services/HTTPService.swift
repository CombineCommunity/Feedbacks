//
//  NetworkService.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

import Combine
import Foundation

enum HTTPService {
    struct HTTPError: Error {}
    
    static func makeURLEncodedRequest<Parameter: Encodable>(method: String, baseUrl: String, path: String, parameter: Parameter?) -> URLRequest? {
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = baseUrl
        urlComponents.path = path
        
        if
            let param = parameter,
            let dict = param.dictionary {
            let query = dict
                .map { (key, value) -> String in
                    "\(key)=\(value)"
                }
                .joined(separator: "&")
            
            urlComponents.percentEncodedQuery = query
        }
        
        guard let url = urlComponents.url else { return nil }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        return urlRequest
    }
    
    static func fetch<Output: Decodable>(request: URLRequest) -> AnyPublisher<Output, Swift.Error> {
        URLSession
            .shared
            .dataTaskPublisher(for: request)
            .tryMap() { element -> Data in
                guard let httpResponse = element.response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return element.data
            }
            .decode(type: Output.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }
}

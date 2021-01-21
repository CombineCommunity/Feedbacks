//
//  GifListRequestParameter.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

struct GifDetailRequestParameter: Encodable {
    let apiKey: String

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
    }
}

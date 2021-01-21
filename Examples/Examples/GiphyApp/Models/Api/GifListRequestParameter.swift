//
//  GifListRequestParameter.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

struct GifListRequestParameter: Encodable {
    let apiKey: String
    let limit: Int
    let offset: Int

    enum CodingKeys: String, CodingKey {
        case apiKey = "api_key"
        case limit
        case offset
    }
}

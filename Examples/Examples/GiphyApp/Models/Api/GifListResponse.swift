//
//  GifListResponse.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

struct GifListResponse: Decodable {
    let data: [GifOverview]
    let pagination: Pagination
    let meta: Meta
}

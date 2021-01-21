//
//  Pagination.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

struct Pagination: Decodable {
    let count: Int
    let offset: Int
    let totalCount: Int

    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case offset
        case count
    }
}

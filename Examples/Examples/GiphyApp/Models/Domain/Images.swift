//
//  Images.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//
struct Images: Decodable, Equatable {
    let fixedHeightData: ImageData

    enum CodingKeys: String, CodingKey {
        case fixedHeightData = "fixed_height"
    }
}

struct ImageData: Decodable, Equatable {
    let url: String
    let mp4: String
}

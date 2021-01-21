//
//  Gif.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

struct Gif: Decodable, Equatable {
    let type: String
    let id: String
    let title: String
    let url: String
    let username: String
    let rating: String
    let images: Images
}

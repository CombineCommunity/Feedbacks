//
//  Meta.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//


struct Meta: Decodable {
    let msg: String
    let status: Int
    let responseId: String

    enum CodingKeys: String, CodingKey {
        case responseId = "response_id"
        case status
        case msg
    }
}

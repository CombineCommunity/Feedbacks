//
//  Encodable+Dictionary.swift
//  Spin.UIKit.Demo
//
//  Created by Thibault Wittemberg on 2020-01-01.
//  Copyright © 2020 Spinners. All rights reserved.
//

import Foundation

// MARK: - Transform an Encodable to a [String: Any] if possible
extension Encodable {
    public var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else { return nil }
        return jsonObject as? [String: Any]
    }
}

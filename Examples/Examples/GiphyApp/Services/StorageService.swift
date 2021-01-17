//
//  StorageService.swift
//  Examples
//
//  Created by Thibault Wittemberg on 2021-01-16.
//

import Foundation

class StorageService {
    private let syncQueue = DispatchQueue(label: UUID().uuidString)
    private var storage = [String: Any]()

    private init() {}

    static let instance = StorageService()

    func load<Output>(key: String) -> Output? {
        syncQueue.sync { [unowned self] in
            return self.storage[key] as? Output
        }
    }

    func store(key: String, value: Any) {
        syncQueue.sync { [unowned self] in
            self.storage[key] = value
        }
    }
}

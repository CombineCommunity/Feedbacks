//
//  DispatchQueue+CurrentLabel.swift
//  
//
//  Created by Thibault Wittemberg on 2020-11-06.
//

import Dispatch

extension DispatchQueue {
    class var currentLabel: String {
        return String(validatingUTF8: __dispatch_queue_get_label(nil))!
    }

    var label: String {
        return String(validatingUTF8: __dispatch_queue_get_label(self))!
    }
}

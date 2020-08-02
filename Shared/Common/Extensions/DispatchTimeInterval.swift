//
//  DispatchTimeInterval.swift
//  Firefox Lockbox
//
//  Created by metin on 02.08.20.
//  Copyright © 2020 Mozilla. All rights reserved.
//

import Foundation

extension DispatchTimeInterval {
    func timeInterval() -> Double {
        switch self {
        case .seconds(let value):
            return Double(value)
        case .milliseconds(let value):
            return Double(value / 1_000)
        case .microseconds(let value):
            return Double(value / 1_000_000)
        case .nanoseconds(let value):
            return Double(value / 1_000_000_000)
        case .never:
            return 0.0
        @unknown default:
            return 0.0
        }
    }
}

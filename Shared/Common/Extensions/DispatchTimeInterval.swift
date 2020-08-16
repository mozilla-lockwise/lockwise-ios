/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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

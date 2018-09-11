/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class Setting {
    enum AutoLock: String {
        case OneMinute
        case FiveMinutes
        case FifteenMinutes
        case ThirtyMinutes
        case OneHour
        case TwelveHours
        case TwentyFourHours
        case Never

        var seconds: Int {
            switch self {
            case .OneMinute:
                return 60
            case .FiveMinutes:
                return 60 * 5
            case .FifteenMinutes:
                return 60 * 15
            case .ThirtyMinutes:
                return 60 * 30
            case .OneHour:
                return 60 * 60
            case .TwelveHours:
                return 60 * 60 * 12
            case .TwentyFourHours:
                return 60 * 60 * 24
            case .Never:
                return 0
            }
        }
    }
}

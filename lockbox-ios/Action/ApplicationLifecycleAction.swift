/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum LifecycleAction: Action {
    case foreground
    case background
    case startup
    case upgrade(from: Int, to: Int)
}

extension LifecycleAction: Equatable {
    static func ==(lhs: LifecycleAction, rhs: LifecycleAction) -> Bool {
        switch (lhs, rhs) {
        case (.foreground, .foreground):
            return true
        case (.background, .background):
            return true
        case (.startup, .startup):
            return true
        case let (.upgrade(l1, l2), .upgrade(r1, r2)):
            return l1 == r1 && l2 == r2
        default:
            return false
        }
    }
}

extension LifecycleAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        switch self {
        case .foreground: return .foreground
        case .background: return .background
        case .startup: return .startup
        // TODO add a TelemetryEventMethod for upgrading
        case .upgrade: return .startup
        }
    }

    var eventObject: TelemetryEventObject {
        return .app
    }

    var value: String? {
        return nil
    }

    var extras: [String: Any?]? {
        return nil
    }
}

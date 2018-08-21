/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum LifecycleAction: Action {
    case foreground, background, startup
}

extension LifecycleAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        switch self {
        case .foreground: return .foreground
        case .background: return .background
        case .startup: return .startup
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

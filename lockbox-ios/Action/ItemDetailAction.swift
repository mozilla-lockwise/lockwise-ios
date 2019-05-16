/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum ItemDetailDisplayAction: Action {
    case togglePassword(displayed: Bool)
    case editMode
    case viewMode
}

extension ItemDetailDisplayAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        return .tap
    }

    var eventObject: TelemetryEventObject {
        switch self {
        case .togglePassword:
            return .revealPassword
        case .viewMode:
            return .entryDetail
        case .editMode:
            return .entryEditor
        }
    }

    var value: String? {
        switch self {
        case .togglePassword(let displayed):
            let displayedString = String(displayed)
            return displayedString
        default:
            return nil
        }
    }

    var extras: [String: Any?]? {
        return nil
    }
}

extension ItemDetailDisplayAction: Equatable {
    static func ==(lhs: ItemDetailDisplayAction, rhs: ItemDetailDisplayAction) -> Bool {
        switch (lhs, rhs) {
        case (.togglePassword(let lhDisplay), .togglePassword(let rhDisplay)):
            return lhDisplay == rhDisplay
        case (.editMode, .editMode):
            return true
        case (.viewMode, .viewMode):
            return true
        default:
            return false
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum CopyField {
    case username, password
}

enum CopyActionType {
    case tap, dnd
}

struct CopyAction: Action {
    let text: String
    let field: CopyField
    let itemID: String
    let actionType: CopyActionType
}

extension CopyAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        switch self.actionType {
        case .tap:
            return .tap
        case .dnd:
            return .dnd
        }
    }

    var eventObject: TelemetryEventObject {
        switch self.field {
        case .password:
            return .entryCopyPasswordButton
        case .username:
            return .entryCopyUsernameButton
        }
    }

    var value: String? {
        return nil
    }

    var extras: [String: Any?]? {
        return [ExtraKey.itemid.rawValue: self.itemID]
    }
}

extension CopyAction: Equatable {
    static func ==(lhs: CopyAction, rhs: CopyAction) -> Bool {
        return lhs.text == rhs.text &&
                lhs.field == rhs.field &&
                lhs.actionType == rhs.actionType
    }
}

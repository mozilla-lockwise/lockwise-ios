/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum CopyField {
    case username, password
}

struct CopyAction: Action {
    let text: String
    let field: CopyField
    let itemID: String
}

extension CopyAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        return .tap
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
                lhs.field == rhs.field
    }
}

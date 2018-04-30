/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

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

struct CopyConfirmationDisplayAction: Action {
    let field: CopyField
}

extension CopyConfirmationDisplayAction: Equatable {
    static func ==(lhs: CopyConfirmationDisplayAction, rhs: CopyConfirmationDisplayAction) -> Bool {
        return lhs.field == rhs.field
    }
}

class CopyActionHandler: ActionHandler {
    static let shared = CopyActionHandler()

    private let dispatcher: Dispatcher
    private let pasteboard: UIPasteboard

    init(dispatcher: Dispatcher = Dispatcher.shared,
         pasteboard: UIPasteboard = UIPasteboard.general) {
        self.dispatcher = dispatcher
        self.pasteboard = pasteboard
    }

    func invoke(_ action: CopyAction) {
        let expireDate = Date().addingTimeInterval(TimeInterval(Constant.number.copyExpireTimeSecs))

        self.pasteboard.setItems([[UIPasteboardTypeAutomatic: action.text]],
                options: [UIPasteboardOption.expirationDate: expireDate])

        self.dispatcher.dispatch(action: CopyConfirmationDisplayAction(field: action.field))
        // only for telemetry purposes, no one is listening for this
        self.dispatcher.dispatch(action: action)
    }
}

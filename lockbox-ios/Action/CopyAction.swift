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
        return TelemetryEventMethod.tap
    }

    var eventObject: TelemetryEventObject {
        switch self.field {
        case .password:
            return TelemetryEventObject.entryCopyPasswordButton
        case .username:
            return TelemetryEventObject.entryCopyUsernameButton
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
    let fieldName: String
}

extension CopyConfirmationDisplayAction: Equatable {
    static func ==(lhs: CopyConfirmationDisplayAction, rhs: CopyConfirmationDisplayAction) -> Bool {
        return lhs.fieldName == rhs.fieldName
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

        var fieldName: String
        switch action.field {
        case .password: fieldName = Constant.string.password
        case .username: fieldName = Constant.string.username
        }

        self.dispatcher.dispatch(action: CopyConfirmationDisplayAction(fieldName: fieldName))
        // only for telemetry purposes, no one is listening for this
        self.dispatcher.dispatch(action: action)
    }
}

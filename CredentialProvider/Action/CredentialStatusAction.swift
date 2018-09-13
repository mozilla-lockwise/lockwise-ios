/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage

enum CredentialStatusAction: Action {
    case extensionConfigured, userCanceled, loginSelected(login: Login, relock: Bool)
}

extension CredentialStatusAction: Equatable {
    static func ==(lhs: CredentialStatusAction, rhs: CredentialStatusAction) -> Bool {
        switch (lhs, rhs) {
        case (.extensionConfigured, .extensionConfigured):
            return true
        case (.userCanceled, .userCanceled):
            return true
        case (.loginSelected(let lhLogin, let lhRelock), .loginSelected(let rhLogin, let rhRelock)):
            return lhLogin == rhLogin && lhRelock == rhRelock
        default:
            return false
        }
    }
}

extension CredentialStatusAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        switch self {
        case .extensionConfigured:
            return .settingChanged
        case .userCanceled:
            return .canceled
        case .loginSelected:
            return .login_selected
        }

    }

    var eventObject: TelemetryEventObject {
        return .autofill
    }

    var value: String? {
        return nil
    }

    var extras: [String : Any?]? {
        return nil
    }
}

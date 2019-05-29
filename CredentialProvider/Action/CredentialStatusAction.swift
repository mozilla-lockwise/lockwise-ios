/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MozillaAppServices
import AuthenticationServices

@available(iOS 12, *)
enum CredentialStatusAction: Action {
    case extensionConfigured,
         cancelled(error: ASExtensionError.Code),
         loginSelected(login: LoginRecord)
}

@available(iOS 12, *)
extension CredentialStatusAction: Equatable {
    static func ==(lhs: CredentialStatusAction, rhs: CredentialStatusAction) -> Bool {
        switch (lhs, rhs) {
        case (.extensionConfigured, .extensionConfigured):
            return true
        case (.cancelled(let lhError), .cancelled(let rhError)):
            return lhError == rhError
        case (.loginSelected(let lhLogin), .loginSelected(let rhLogin)):
            return lhLogin == rhLogin
        default:
            return false
        }
    }
}

@available(iOS 12, *)
extension CredentialStatusAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        switch self {
        case .extensionConfigured:
            return .settingChanged
        case .cancelled:
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

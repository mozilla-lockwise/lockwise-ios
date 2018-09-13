/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AuthenticationServices

enum CredentialProviderAction: Action {
    case refresh, authenticationRequested, authenticated
}

extension CredentialProviderAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        switch self {
        case .refresh:
            return .refresh
        case .authenticationRequested:
            return .autofill_locked
        case .authenticated:
            return .autofill_unlocked
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

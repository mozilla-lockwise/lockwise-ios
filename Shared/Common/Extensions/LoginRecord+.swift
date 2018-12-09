/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Sync15Logins
import AuthenticationServices

extension LoginRecord: Equatable {
    public static func == (lhs: LoginRecord, rhs: LoginRecord) -> Bool {
        return lhs.id == rhs.id &&
            lhs.username == rhs.username
            rhs.password == rhs.password
    }
}

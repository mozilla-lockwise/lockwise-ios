/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxAClient

extension AccessTokenInfo: Equatable {
    public static func ==(lhs: AccessTokenInfo, rhs: AccessTokenInfo) -> Bool {
        return lhs.key == rhs.key &&
                lhs.token == rhs.token &&
                lhs.scope == rhs.scope &&
                lhs.expiresAt == rhs.expiresAt
    }
}

extension Profile: Equatable {
    public static func ==(lhs: Profile, rhs: Profile) -> Bool {
        return lhs.email == rhs.email &&
                lhs.displayName == rhs.displayName &&
                lhs.avatar == rhs.avatar &&
                lhs.uid == rhs.uid
    }
}

extension Avatar: Equatable {
    public static func ==(lhs: Avatar, rhs: Avatar) -> Bool {
        return lhs.isDefault == rhs.isDefault &&
                lhs.url == rhs.url
    }
}

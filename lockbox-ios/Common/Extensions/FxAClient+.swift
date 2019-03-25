/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxAClient
import Logins

extension SyncUnlockInfo: Equatable {
    public static func ==(lhs: SyncUnlockInfo, rhs: SyncUnlockInfo) -> Bool {
        return lhs.syncKey == rhs.syncKey &&
                lhs.fxaAccessToken == rhs.fxaAccessToken
    }
}

extension Avatar: Equatable {
    public static func ==(lhs: Avatar, rhs: Avatar) -> Bool {
        return lhs.url == rhs.url &&
            lhs.isDefault == rhs.isDefault
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

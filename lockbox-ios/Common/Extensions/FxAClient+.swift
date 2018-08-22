/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxAClient

extension OAuthInfo: Equatable {
    public static func ==(lhs: OAuthInfo, rhs: OAuthInfo) -> Bool {
        return lhs.keys == rhs.keys &&
                lhs.accessToken == rhs.accessToken &&
                lhs.scopes == rhs.scopes
    }
}

extension Profile: Equatable {
    public static func ==(lhs: Profile, rhs: Profile) -> Bool {
        return lhs.email == rhs.email &&
                lhs.displayName == rhs.displayName &&
                lhs.avatar == rhs.displayName &&
                lhs.uid == rhs.uid
    }
}

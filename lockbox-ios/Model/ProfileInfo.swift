/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ProfileInfo: Codable {
    var email: String
    var displayName: String?
    var avatar: URL?

    init(email: String, displayName: String? = nil, avatar: URL? = nil) {
        self.email = email
        self.displayName = displayName
        self.avatar = avatar
    }

    class Builder {
        private var info: ProfileInfo!

        init() {
            self.info = ProfileInfo(email: "")
        }

        func build() -> ProfileInfo {
            return self.info
        }

        func email(_ email: String) -> Builder {
            self.info.email = email
            return self
        }

        func displayName(_ displayName: String?) -> Builder {
            self.info.displayName = displayName
            return self
        }

        func avatar(_ avatar: URL?) -> Builder {
            self.info.avatar = avatar
            return self
        }
    }
}

extension ProfileInfo: Equatable {
    static func ==(lhs: ProfileInfo, rhs: ProfileInfo) -> Bool {
        return lhs.email == rhs.email
    }
}

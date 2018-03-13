/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ProfileInfo: Codable {
    var uid: String
    var email: String
    var displayName: String?
    var avatar: String?

    init(uid: String, email: String, displayName: String? = nil, avatar: String? = nil) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.avatar = avatar
    }

    enum CodingKeys: String, CodingKey {
        case uid = "sub"
        case displayName = "displayName"
        case email = "email"
        case avatar = "avatar"
    }

    class Builder {
        private var info: ProfileInfo!

        init() {
            self.info = ProfileInfo(uid: "", email: "")
        }

        func build() -> ProfileInfo {
            return self.info
        }

        func uid(_ uid: String) -> Builder {
            self.info.uid = uid
            return self
        }

        func email(_ email: String) -> Builder {
            self.info.email = email
            return self
        }

        func displayName(_ displayName: String) -> Builder {
            self.info.displayName = displayName
            return self
        }

        func avatar(_ avatar: String) -> Builder {
            self.info.avatar = avatar
            return self
        }
    }
}

extension ProfileInfo: Equatable {
    static func ==(lhs: ProfileInfo, rhs: ProfileInfo) -> Bool {
        return lhs.uid == rhs.uid &&
                lhs.email == rhs.email
    }
}

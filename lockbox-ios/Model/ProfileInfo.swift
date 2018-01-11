/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class ProfileInfo: Codable {
    var uid:String
    var email:String

    init(uid:String, email:String) {
        self.uid = uid
        self.email = email
    }

    class Builder {
        private var info:ProfileInfo!

        init() {
            self.info = ProfileInfo(uid: "", email: "")
        }

        func build() -> ProfileInfo {
            return self.info
        }

        func uid(_ uid:String) -> Builder {
            self.info.uid = uid
            return self
        }

        func email(_ email:String) -> Builder {
            self.info.email = email
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
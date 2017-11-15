/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class OAuthInfo: Codable {
    var uid:String
    var email:String
    var accessToken:String
    var expiresAt:Date
    var refreshToken:String
    var idToken:String
    var scopedKey:String

    init(uid:String,
         email:String,
         accessToken:String,
         expiresAt:Date,
         refreshToken:String,
         idToken:String,
         scopedKey:String) {
        self.uid = uid
        self.email = email
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.scopedKey = scopedKey
    }

    class Builder {
        private var info:OAuthInfo!

        init() {
            self.info = OAuthInfo(uid:"",
                    email:"",
                    accessToken:"",
                    expiresAt:Date(),
                    refreshToken:"",
                    idToken:"",
                    scopedKey:"")
        }

        func build() -> OAuthInfo {
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

        func accessToken(_ accessToken:String) -> Builder {
            self.info.accessToken = accessToken
            return self
        }

        func expiresAt(_ expiresAt:Date) -> Builder {
            self.info.expiresAt = expiresAt
            return self
        }

        func refreshToken(_ refreshToken:String) -> Builder {
            self.info.refreshToken = refreshToken
            return self
        }

        func idToken(_ idToken:String) -> Builder {
            self.info.idToken = idToken
            return self
        }

        func scopedKey(_ scopedKey:String) -> Builder {
            self.info.scopedKey = scopedKey
            return self
        }
    }
}
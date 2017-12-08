/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class OAuthInfo: Codable {
    var accessToken:String
    var expiresAt:Date
    var refreshToken:String
    var idToken:String
    var keysJWE:String

    init(accessToken:String,
         expiresAt:Date,
         refreshToken:String,
         idToken:String,
         keysJWE:String) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt
        self.refreshToken = refreshToken
        self.idToken = idToken
        self.keysJWE = keysJWE
    }

    class Builder {
        private var info:OAuthInfo!

        init() {
            self.info = OAuthInfo(
                    accessToken:"",
                    expiresAt:Date(),
                    refreshToken:"",
                    idToken:"",
                    keysJWE:"")
        }

        func build() -> OAuthInfo {
            return self.info
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

        func keysJWE(_ keysJWE:String) -> Builder {
            self.info.keysJWE = keysJWE
            return self
        }
    }
}
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

struct Constant {
    struct app {
        static let redirectURI = "https://2aa95473a5115d5f3deb36bb6875cf76f05e4c4d.extensions.allizom.org"
    }

    struct color {
        static let lightGrey = UIColor(hex: 0xEFEFEF)
        static let lockBoxBlue = UIColor(hex: 0x0088D9)
        static let lockBoxTeal = UIColor(hex: 0x00BAD6)
        static let kebabBlue = UIColor(hex: 0x003EAA)
    }

    struct fxa {
        static let clientID = "1b024772203a0849"
        static let oauthHost = "oauth.accounts.firefox.com"
        static let profileHost = "profile.accounts.firefox.com"
    }

    struct string {
        static let cancel = NSLocalizedString("cancel", value:"Cancel", comment: "Cancel button title")
        static let noUsername = NSLocalizedString("no_username", value:"(no username)", comment: "placeholder text when there is no username")
        static let ok = NSLocalizedString("ok", value:"OK", comment: "ok")
        static let yourLockbox = NSLocalizedString("your_lockbox", value:"Your Lockbox", comment: "item list title")
    }
}

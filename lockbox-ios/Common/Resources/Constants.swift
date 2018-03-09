/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// swiftlint:disable line_length

import Foundation
import UIKit

struct Constant {
    struct app {
        static let redirectURI = "https://mozilla-lockbox.github.io/fxa/ios-redirect.html"
    }

    struct color {
        static let lightGrey = UIColor(hex: 0xEFEFEF)
        static let lockBoxBlue = UIColor(hex: 0x0088D9)
        static let lockBoxTeal = UIColor(hex: 0x00BAD6)
        static let tableViewCellHighlighted = UIColor(hex: 0xe5eff9)
    }

    struct fxa {
        static let clientID = "98adfa37698f255b"
        static let oauthHost = "oauth.accounts.firefox.com"
        static let profileHost = "profile.accounts.firefox.com"
    }

    struct string {
        static let back = NSLocalizedString("back", value: "Back", comment: "Back button title")
        static let cancel = NSLocalizedString("cancel", value: "Cancel", comment: "Cancel button title")
        static let fieldNameCopied = NSLocalizedString("fieldNameCopied", value: "%@ copied to clipboard", comment: "Alert text when a field has been copied, with an interpolated field name value")
        static let notes = NSLocalizedString("notes", value: "Notes", comment: "Section title for the notes field on the item detail screen")
        static let usernamePlaceholder = NSLocalizedString("username_placeholder", value: "(no username)", comment: "Placeholder text when there is no username")
        static let ok = NSLocalizedString("ok", value: "OK", comment: "Ok button title")
        static let password = NSLocalizedString("password", value: "Password", comment: "Section title text for the password on the item detail screen")
        static let unnamedEntry = NSLocalizedString("unnamed_entry", value: "unnamed entry", comment: "Placeholder text for when there is no entry name")
        static let username = NSLocalizedString("username", value: "Username", comment: "Section title text for username on the item detail screen")
        static let webAddress = NSLocalizedString("web_address", value: "Web Address", comment: "Section title text for the web address on the item detail screen")
        static let yourLockbox = NSLocalizedString("your_lockbox", value: "Your Lockbox", comment: "Title appearing above the list of entries on the main screen of the app")
    }

    struct number {
        static let displayStatusAlertLength = TimeInterval(1.5)
        static let displayStatusAlertFade = TimeInterval(0.3)
        static let displayStatusAlertOpacity: CGFloat = 0.75
        static let displayStatusAlertYPercentage: CGFloat = 0.4
    }
}

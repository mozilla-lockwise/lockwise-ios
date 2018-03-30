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
        static let kebabBlue = UIColor(hex: 0x003EAA)
        static let settingsHeader = UIColor(hex: 0x737373)
        static let settingsBackground = UIColor(hex: 0xEFEFEF)
        static let tableViewCellHighlighted = UIColor(hex: 0xe5eff9)
    }

    struct fxa {
        static let clientID = "98adfa37698f255b"
        static let oauthHost = "oauth.accounts.firefox.com"
        static let profileHost = "profile.accounts.firefox.com"
    }

    struct string {
        static let alphabetically = NSLocalizedString("alphabetically", value: "Alphabetically", comment: "Label for the option sheet action allowing users to sort an entry list alphabetically")
        static let aToZ = NSLocalizedString("a_to_z", value: "A-Z", comment: "Label for the button allowing users to sort an entry list alphabetically")
        static let back = NSLocalizedString("back", value: "Back", comment: "Back button title")
        static let cancel = NSLocalizedString("cancel", value: "Cancel", comment: "Cancel button title")
        static let done = NSLocalizedString("done", value: "Done", comment: "Text on button to close settings")
        static let fieldNameCopied = NSLocalizedString("fieldNameCopied", value: "%@ copied to clipboard", comment: "Alert text when a field has been copied, with an interpolated field name value")
        static let notes = NSLocalizedString("notes", value: "Notes", comment: "Section title for the notes field on the item detail screen")
        static let ok = NSLocalizedString("ok", value: "OK", comment: "Ok button title")
        static let password = NSLocalizedString("password", value: "Password", comment: "Section title text for the password on the item detail screen")
        static let recent = NSLocalizedString("recent", value: "Recent", comment: "Button title when entries list is sorted by most recently used entry")
        static let recentlyUsed = NSLocalizedString("recently_used", value: "Recently Used", comment: "Label for the option sheet action allowing users to sort an entry list by the most recently used entries")
        static let sortEntries = NSLocalizedString("sort_entries", value: "Sort Entries", comment: "Title for the option sheet allowing users to sort entries")
        static let unnamedEntry = NSLocalizedString("unnamed_entry", value: "unnamed entry", comment: "Placeholder text for when there is no entry name")
        static let username = NSLocalizedString("username", value: "Username", comment: "Section title text for username on the item detail screen")
        static let usernamePlaceholder = NSLocalizedString("username_placeholder", value: "(no username)", comment: "Placeholder text when there is no username")
        static let webAddress = NSLocalizedString("web_address", value: "Web Address", comment: "Section title text for the web address on the item detail screen")
        static let yourLockbox = NSLocalizedString("your_lockbox", value: "Your Lockbox", comment: "Title appearing above the list of entries on the main screen of the app")
        static let settingsHelpSectionHeader = NSLocalizedString("settings.help.header", value: "HELP", comment: "Help section label in settings")
        static let settingsConfigurationSectionHeader = NSLocalizedString("settings.configuration.header", value: "CONFIGURATION", comment: "Configuration label in settings")
        static let settingsTitle = NSLocalizedString("settings.title", value: "Settings", comment: "Title on settings screen")
        static let settingsProvideFeedback = NSLocalizedString("settings.provideFeedback", value: "Provide Feedback", comment: "Provide feedback option in settings")
        static let settingsFaq = NSLocalizedString("settings.faq", value: "FAQ", comment: "FAQ option in settings")
        static let settingsEnableInBrowser = NSLocalizedString("settings.enableInBrowser", value: "Enable In Browser", comment: "Enable In Browser option in settings")
        static let settingsAccount = NSLocalizedString("settings.account", value: "Account", comment: "Account option in settings")
        static let settingsAutoLock = NSLocalizedString("settings.autoLock", value: "Auto Lock", comment: "Auto Lock option in settings")
        static let settingsTouchId = NSLocalizedString("settings.touchId", value: "Touch ID", comment: "Touch ID option in settings")
        static let settingsFaceId = NSLocalizedString("settings.faceId", value: "Face ID", comment: "Face ID option in settings")
    }

    struct number {
        static let displayStatusAlertLength = TimeInterval(1.5)
        static let displayStatusAlertFade = TimeInterval(0.3)
        static let displayStatusAlertOpacity: CGFloat = 0.75
        static let displayStatusAlertYPercentage: CGFloat = 0.4
    }
}

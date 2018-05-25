/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// swiftlint:disable line_length

import Foundation
import UIKit

struct Constant {
    struct app {
        static let redirectURI = "https://mozilla-lockbox.github.io/fxa/ios-redirect.html"
        static let faqURL = "https://lockbox.firefox.com/faq.html"
        static let provideFeedbackURL = "https://qsurvey.mozilla.com/s3/Lockbox-Input"
        static let useLockboxFAQ = "https://lockbox.firefox.com/faq.html#how-do-i-use-lockbox"
        static let enableSyncFAQ = "https://lockbox.firefox.com/faq.html#how-do-i-enable-sync-on-firefox"
        static let editExistingEntriesFAQ = "https://lockbox.firefox.com/faq.html#how-do-i-edit-existing-entries"
    }

    struct color {
        static let cellBorderGrey = UIColor(hex: 0xC8C7CC)
        static let viewBackground = UIColor(hex: 0xEDEDF0)
        static let lightGrey = UIColor(hex: 0xEFEFEF)
        static let lockBoxBlue = UIColor(hex: 0x0060DF)
        static let lockBoxTeal = UIColor(hex: 0x00C8D7)
        static let kebabBlue = UIColor(hex: 0x003EAA)
        static let settingsHeader = UIColor(hex: 0x737373)
        static let tableViewCellHighlighted = UIColor(hex: 0xE5EFF9)
        static let buttonTitleColorNormalState = UIColor.white
        static let buttonTitleColorOtherState = UIColor(white: 1.0, alpha: 0.6)
    }

    struct fxa {
        static let clientID = "98adfa37698f255b"
        static let oauthHost = "oauth.accounts.firefox.com"
        static let profileHost = "profile.accounts.firefox.com"
    }

    struct string {
        static let account = NSLocalizedString("account", value: "Account", comment: "Title for settings page letting users manage their accounts")
        static let alphabetically = NSLocalizedString("alphabetically", value: "Alphabetically", comment: "Label for the option sheet action allowing users to sort an entry list alphabetically")
        static let aToZ = NSLocalizedString("a_to_z", value: "A-Z", comment: "Label for the button allowing users to sort an entry list alphabetically")
        static let back = NSLocalizedString("back", value: "Back", comment: "Back button title")
        static let cancel = NSLocalizedString("cancel", value: "Cancel", comment: "Cancel button title")
        static let close = NSLocalizedString("close", value: "Close", comment: "Close button title")
        static let unlink = NSLocalizedString("unlink", value: "Disconnect", comment: "Unlink aka Disconnect button title")
        static let done = NSLocalizedString("done", value: "Done", comment: "Text on button to close settings")
        static let confirmDialogTitle = NSLocalizedString("confirm_dialog_title", value: "Disconnect Firefox Lockbox?", comment: "Confirm dialog title")
        static let confirmDialogMessage = NSLocalizedString("confirm_dialog_message", value: "This will delete your Firefox Account information and all saved entries from Firefox Lockbox.", comment: "Confirm dialog message")
        static let fieldNameCopied = NSLocalizedString("fieldNameCopied", value: "%@ copied", comment: "Alert text when a field has been copied, with an interpolated field name value")
        static let notes = NSLocalizedString("notes", value: "Notes", comment: "Section title for the notes field on the item detail screen")
        static let ok = NSLocalizedString("ok", value: "OK", comment: "Ok button title")
        static let password = NSLocalizedString("password", value: "Password", comment: "Section title text for the password on the item detail screen")
        static let recent = NSLocalizedString("recent", value: "Recent", comment: "Button title when entries list is sorted by most recently used entry")
        static let recentlyUsed = NSLocalizedString("recently_used", value: "Recently Used", comment: "Label for the option sheet action allowing users to sort an entry list by the most recently used entries")
        static let signInFaceID = NSLocalizedString("signin_with_faceid", value: "Sign in with Face ID", comment: "Label for the button to unlock the device using Face ID")
        static let signInTouchID = NSLocalizedString("signin_with_touchid", value: "Sign in with Touch ID", comment: "Label for the button to unlock the device using Touch ID")
        static let sortEntries = NSLocalizedString("sort_entries", value: "Sort Entries", comment: "Title for the option sheet allowing users to sort entries")
        static let unnamedEntry = NSLocalizedString("unnamed_entry", value: "unnamed entry", comment: "Placeholder text for when there is no entry name")
        static let username = NSLocalizedString("username", value: "Username", comment: "Section title text for username on the item detail screen")
        static let usernamePlaceholder = NSLocalizedString("username_placeholder", value: "(no username)", comment: "Placeholder text when there is no username")
        static let unlockPlaceholder = NSLocalizedString("unlock_placeholder", value: "This will unlock the app.", comment: "Placeholder text when the user's email is unavailable while unlocking Lockbox, shown in Touch ID and passcode prompts")
        static let webAddress = NSLocalizedString("web_address", value: "Web Address", comment: "Section title text for the web address on the item detail screen")
        static let yourLockbox = NSLocalizedString("your_lockbox", value: "Your Firefox Lockbox", comment: "Title appearing above the list of entries on the main screen of the app")
        static let settingsSupportSectionHeader = NSLocalizedString("settings.support.header", value: "SUPPORT", comment: "Support section label in settings")
        static let settingsConfigurationSectionHeader = NSLocalizedString("settings.configuration.header", value: "CONFIGURATION", comment: "Configuration label in settings")
        static let settingsTitle = NSLocalizedString("settings.title", value: "Settings", comment: "Title on settings screen")
        static let settingsProvideFeedback = NSLocalizedString("settings.provideFeedback", value: "Send Feedback", comment: "Send feedback option in settings")
        static let faq = NSLocalizedString("settings.faq", value: "FAQ", comment: "FAQ option in settings")
        static let settingsAccount = NSLocalizedString("settings.account", value: "Account", comment: "Account option in settings")
        static let settingsAutoLock = NSLocalizedString("settings.autoLock", value: "Auto Lock", comment: "Auto Lock option in settings")
        static let settingsBrowser = NSLocalizedString("settings.browser", value: "Open Websites in", comment: "Preferred Browser option in settings")
        static let autoLockOnAppExit = NSLocalizedString("settings.autoLock.onAppExit", value: "On app exit", comment: "On app exit auto lock setting")
        static let autoLockOneMinute = NSLocalizedString("settings.autoLock.oneMinute", value: "1 minute", comment: "1 minute auto lock setting")
        static let autoLockFiveMinutes = NSLocalizedString("settings.autoLock.fiveMinutes", value: "5 minutes", comment: "5 minutes auto lock setting")
        static let autoLockThirtyMinutes = NSLocalizedString("settings.autoLock.thirtyMinutes", value: "30 minutes", comment: "30 minutes auto lock setting")
        static let autoLockOneHour = NSLocalizedString("settings.autoLock.oneHour", value: "1 hour", comment: "1 hour auto lock setting")
        static let autoLockTwelveHours = NSLocalizedString("settings.autoLock.twelveHour", value: "12 hours", comment: "12 hours auto lock setting")
        static let autoLockTwentyFourHours = NSLocalizedString("settings.autoLock.twentyFourHour", value: "24 hours", comment: "24 hours auto lock setting")
        static let autoLockNever = NSLocalizedString("settings.autoLock.never", value: "Never", comment: "Never")
        static let autoLockHeader = NSLocalizedString("settings.autoLock.header", value: "Sign out of Firefox Lockbox after", comment: "Header displayed above auto lock settings")
        static let settingsBrowserChrome = NSLocalizedString("settings.browser.chrome", value: "Google Chrome", comment: "Chrome Browser")
        static let settingsBrowserFirefox = NSLocalizedString("settings.browser.firefox", value: "Firefox", comment: "Firefox Browser")
        static let settingsBrowserFocus = NSLocalizedString("settings.browser.focus", value: "Firefox Focus", comment: "Focus Browser")
        static let settingsBrowserSafari = NSLocalizedString("settings.browser.safari", value: "Safari", comment: "Safari Browser")
        static let settingsUsageData = NSLocalizedString("settings.usageData", value: "Send Usage Data", comment: "Setting to send usage data")
        static let settingsUsageDataSubtitle = NSLocalizedString("settings.usageData.subtitle", value: "Mozilla strives to only collect what we need to provide and improve Firefox Lockbox for everyone. ", comment: "Setting for send usage data subtitle")
        static let learnMore = NSLocalizedString("settings.learnMore", value: "Learn More", comment: "Label for link to learn more")
        static let notUsingPasscode = NSLocalizedString("not_using_passcode", value: "You're not using a passcode.", comment: "Title for dialog box with passcode setting information")
        static let passcodeInformation = NSLocalizedString("passcode_info", value: "You should use a passcode to lock your iPhone. Without a passcode, anyone who has your iPhone can access the information saved here.", comment: "Informative text about the ")
        static let skip = NSLocalizedString("skip", value: "Skip", comment: "Label for button allowing users to skip setting passcode or biometrics on device")
        static let setPasscode = NSLocalizedString("set_passcode", value: "Set Passcode", comment: "Label for button allowing users to go to passcode settings")
    }

    struct number {
        static let displayStatusAlertLength = TimeInterval(1.5)
        static let displayAlertFade = TimeInterval(0.3)
        static let displayAlertOpacity: CGFloat = 0.75
        static let displayAlertYPercentage: CGFloat = 0.4
        static let fxaButtonTopSpaceFirstLogin: CGFloat = 88.0
        static let fxaButtonTopSpaceUnlock: CGFloat = 40.0
        static let copyExpireTimeSecs = 60
    }

    struct setting {
        static let defaultBiometricLockEnabled = false
        static let defaultAutoLockTimeout = AutoLockSetting.FiveMinutes
        static let defaultPreferredBrowser = PreferredBrowserSetting.Safari
        static let defaultRecordUsageData = true
    }
}

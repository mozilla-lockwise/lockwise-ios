/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// swiftlint:disable line_length

import Foundation
import UIKit

extension Constant.app {
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    static let appVersionCode = 2 // this is the version of the app that will drive updates.
    static let faqURL = "https://lockbox.firefox.com/faq.html"
    static let privacyURL = "https://lockbox.firefox.com/privacy.html"
    static let provideFeedbackURL = "https://qsurvey.mozilla.com/s3/Lockbox-Input?ver=\(appVersion ?? "1.1")"
    static let getSupportURL = "https://discourse.mozilla.org/c/test-pilot/lockbox"
        static let useLockboxFAQ = faqURL + "#how-do-i-use-firefox-lockbox"
    static let enableSyncFAQ = faqURL + "#how-do-i-enable-sync-on-firefox"
    static let editExistingEntriesFAQ = faqURL + "#how-do-i-edit-existing-entries"
    static let securityFAQ = faqURL + "#what-security-technology-does-firefox-lockbox-use"
    static let createNewEntriesFAQ = faqURL + "#how-do-i-create-new-entries"
    static let adjustAppToken = "383z4i46o48w"
}

extension Constant.fxa {
    static let redirectURI = "https://lockbox.firefox.com/fxa/ios-redirect.html"
    static let clientID = "98adfa37698f255b"
}

extension Constant.setting {
    static let defaultPreferredBrowser = Setting.PreferredBrowser.Safari
    static let defaultRecordUsageData = true
    static let defaultItemListSort = Setting.ItemListSort.alphabetically
}

extension Constant {
    struct color {
        static let cellBorderGrey = UIColor(hex: 0xC8C7CC)
        static let viewBackground = UIColor(hex: 0xEDEDF0)
        static let lightGrey = UIColor(hex: 0xEFEFEF)
        static let lockBoxBlue = UIColor(hex: 0x0060DF)
        static let lockBoxTeal = UIColor(hex: 0x00C8D7)
        static let settingsHeader = UIColor(hex: 0x737373)
        static let tableViewCellHighlighted = UIColor(hex: 0xE5EFF9)
        static let buttonTitleColorNormalState = UIColor.white
        static let buttonTitleColorOtherState = UIColor(white: 1.0, alpha: 0.6)
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
        static let unlockFaceID = NSLocalizedString("unlock_with_faceid", value: "Unlock with Face ID", comment: "Label for the button to unlock the device using Face ID")
        static let unlockTouchID = NSLocalizedString("unlock_with_touchid", value: "Unlock with Touch ID", comment: "Label for the button to unlock the device using Touch ID")
        static let unlockPIN = NSLocalizedString("unlock_with_pin", value: "Unlock with Passcode", comment: "Label for the button to unlock the device using a device passcode")
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
        static let settingsGetSupport = NSLocalizedString("settings.getSupport", value: "Ask a Question", comment: "Support link to Discourse discussion forum")
        static let faq = NSLocalizedString("settings.faq", value: "FAQ", comment: "FAQ option in settings")
        static let settingsAccount = NSLocalizedString("settings.account", value: "Account", comment: "Account option in settings")
        static let settingsAutoLock = NSLocalizedString("settings.autoLock", value: "Auto Lock", comment: "Auto Lock option in settings")
        static let settingsBrowser = NSLocalizedString("settings.browser", value: "Open Websites in", comment: "Preferred Browser option in settings")
        static let autoLockOneMinute = NSLocalizedString("settings.autoLock.oneMinute", value: "1 minute", comment: "1 minute auto lock setting")
        static let autoLockFiveMinutes = NSLocalizedString("settings.autoLock.fiveMinutes", value: "5 minutes", comment: "5 minutes auto lock setting")
        static let autoLockFifteenMinutes = NSLocalizedString("settings.autoLock.fifteenMinutes", value: "15 minutes", comment: "15 minutes auto lock setting")
        static let autoLockThirtyMinutes = NSLocalizedString("settings.autoLock.thirtyMinutes", value: "30 minutes", comment: "30 minutes auto lock setting")
        static let autoLockOneHour = NSLocalizedString("settings.autoLock.oneHour", value: "1 hour", comment: "1 hour auto lock setting")
        static let autoLockTwelveHours = NSLocalizedString("settings.autoLock.twelveHour", value: "12 hours", comment: "12 hours auto lock setting")
        static let autoLockTwentyFourHours = NSLocalizedString("settings.autoLock.twentyFourHour", value: "24 hours", comment: "24 hours auto lock setting")
        static let autoLockNever = NSLocalizedString("settings.autoLock.never", value: "Never", comment: "Never")
        static let autoLockHeader = NSLocalizedString("settings.autoLock.header", value: "Sign out of Firefox Lockbox after", comment: "Header displayed above auto lock settings")
        static let settingsBrowserChrome = NSLocalizedString("settings.browser.chrome", value: "Google Chrome", comment: "Chrome Browser")
        static let settingsBrowserFirefox = NSLocalizedString("settings.browser.firefox", value: "Firefox", comment: "Firefox Browser")
        static let settingsBrowserFocus = NSLocalizedString("settings.browser.focus", value: "Firefox Focus", comment: "Focus Browser")
        static let settingsBrowserKlar = NSLocalizedString("settings.browser.klar", value: "Firefox Klar", comment: "Klar Browser")
        static let settingsBrowserSafari = NSLocalizedString("settings.browser.safari", value: "Safari", comment: "Safari Browser")
        static let settingsUsageData = NSLocalizedString("settings.usageData", value: "Send Usage Data", comment: "Setting to send usage data")
        static let settingsUsageDataSubtitle = NSLocalizedString("settings.usageData.subtitle", value: "Mozilla strives to only collect what we need to provide and improve Firefox Lockbox for everyone. ", comment: "Setting for send usage data subtitle")
        static let settingsAppVersion = NSLocalizedString("settings.appVersion", value: "App Version", comment: "App Version setting label")
        static let learnMore = NSLocalizedString("settings.learnMore", value: "Learn More", comment: "Label for link to learn more")
        static let notUsingPasscode = NSLocalizedString("not_using_passcode", value: "You're not using a passcode.", comment: "Title for dialog box with passcode setting information")
        static let passcodeInformation = NSLocalizedString("passcode_info", value: "You should use a passcode to lock your iPhone. Without a passcode, anyone who has your iPhone can access the information saved here.", comment: "Informative text about the ")
        static let passcodeDetailInformation = NSLocalizedString("passcode_detail_information", value: "In order to lock Firefox Lockbox, a passcode must be set up on your device. Without a passcode, anyone who has your iPhone can access the information saved here.", comment: "Message for dialog box with passcode reminder")
        static let skip = NSLocalizedString("skip", value: "Skip", comment: "Label for button allowing users to skip setting passcode or biometrics on device")
        static let setPasscode = NSLocalizedString("set_passcode", value: "Set Passcode", comment: "Label for button allowing users to go to passcode settings")
        static let sortOptionsAccessibilityID = NSLocalizedString("sorting_options", value: "Select options for sorting your list of entries (currently %@)", comment: "Accessibility identifier for the sorting options button")
        static let settingsAccessibilityID = NSLocalizedString("settings_button", value: "Settings", comment: "Accessibility identifier for the settings button")
        static let websiteCellAccessibilityLabel = NSLocalizedString("website_accessibility_instructions", value: "Web address: double tap to open in browser %@", comment: "Accessibility label and instructions for web address section of entry details")
        static let usernameCellAccessibilityLabel = NSLocalizedString("username_accessibility_instructions", value: "Username: double tap to copy %@", comment: "Accessibility label and instructions for username section of entry details")
        static let passwordCellAccessibilityLabel = NSLocalizedString("password_accessibility_instructions", value: "Password: double tap to copy %@", comment: "Accessibility label and instructions for password section of entry details")
        static let syncingYourEntries = NSLocalizedString("syncing_entries", value: "Syncing your entries", comment: "Label and accessibility callout for syncing your entries spinner and HUD")
        static let doneSyncingYourEntries = NSLocalizedString("syncing_entries", value: "Done syncing your entries", comment: "Accessibility callout for finishing syncing your entries")
        static let installBrowserAccessibilityLabel = NSLocalizedString("install_browser_prompt", value: "%@ disabled, install this browser to make it available", comment: "Accessibility instructions for disabled web browser options")
        static let onboardingSecurityPostfix = NSLocalizedString("onboarding.encryption", value: "256-bit encryption", comment: "Name of link to algorithm used by Lockbox for encryption")
        static let reauthenticationRequired = NSLocalizedString("reauth_required", value: "Reauthentication Required", comment: "Title of dialog box displayed when users need to reauthenticate")
        static let appUpdateDisclaimer = NSLocalizedString("app_update_explanation", value: "Due to a recent app update, we will need you to sign in again. Apologies for the inconvenience.", comment: "Message in dialog box when users need to reauthenticate explaining application update")
        static let continueText = NSLocalizedString("continue", value: "Continue", comment: "Button title when agreeing to proceed to access Lockbox.")
    }

    struct number {
        static let displayStatusAlertLength = isRunningTest ? TimeInterval(0.0) : TimeInterval(1.5)
        static let displayAlertFade = isRunningTest ? TimeInterval(0.0) : TimeInterval(0.3)
        static let displayAlertOpacity: CGFloat = 0.75
        static let displayAlertYPercentage: CGFloat = 0.4
        static let fxaButtonTopSpaceFirstLogin: CGFloat = 88.0
        static let fxaButtonTopSpaceUnlock: CGFloat = 40.0
        static let copyExpireTimeSecs = 60
        static let minimumSpinnerHUDTime = isRunningTest ? TimeInterval(0.0) : TimeInterval(1.0)
    }
}

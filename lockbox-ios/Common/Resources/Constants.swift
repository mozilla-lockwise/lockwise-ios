/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// swiftlint:disable line_length

import Foundation
import UIKit

extension Constant.app {
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    static let appVersionCode = 3 // this is the version of the app that will drive updates.
    static let faqURL = "https://lockwise.firefox.com/faq.html"
    static let faqURLtop = faqURL + "#top"
    static let privacyURL = "https://lockwise.firefox.com/privacy.html"
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
}

extension Constant.string {
    static let account = NSLocalizedString("account", value: "Account", comment: "Title for settings page letting users manage their accounts")
    static let alphabetically = NSLocalizedString("alphabetically", value: "Alphabetically", comment: "Label for the option sheet action allowing users to sort the logins list alphabetically")
    static let aToZ = NSLocalizedString("a_to_z", value: "A-Z", comment: "Label for the button allowing users to sort the logins list alphabetically")
    static let back = NSLocalizedString("back", value: "Back", comment: "Back button title")
    static let close = NSLocalizedString("close", value: "Close", comment: "Close button title")
    static let unlink = NSLocalizedString("unlink", value: "Disconnect", comment: "Unlink aka Disconnect button title")
    static let done = NSLocalizedString("done", value: "Done", comment: "Text on button to close settings")
    static let confirmDialogTitle = NSLocalizedString("confirm_dialog_title", value: "Disconnect %@?", comment: "Confirm dialog title. %@ will be replaced with the application name")
    static let confirmDialogMessage = NSLocalizedString("confirm_dialog_message", value: "This will delete your Firefox Account information and all saved logins from %@.", comment: "Confirm dialog message")
    static let fieldNameCopied = NSLocalizedString("fieldNameCopied", value: "%@ copied", comment: "Alert text when a field has been copied. %@ will be replaced with the field name that was copied")
    static let notes = NSLocalizedString("notes", value: "Notes", comment: "Section title for the notes field on the item detail screen")
    static let password = NSLocalizedString("password", value: "Password", comment: "Section title text for the password on the item detail screen")
    static let recent = NSLocalizedString("recent", value: "Recent", comment: "Button title when logins list is sorted by most recently used login")
    static let recentlyUsed = NSLocalizedString("recently_used", value: "Recently Used", comment: "Label for the option sheet action allowing users to sort the logins list by the most recently used logins")
    static let unlockFaceID = NSLocalizedString("unlock_with_faceid", value: "Unlock with Face ID", comment: "Label for the button to unlock the device using Face ID")
    static let unlockTouchID = NSLocalizedString("unlock_with_touchid", value: "Unlock with Touch ID", comment: "Label for the button to unlock the device using Touch ID")
    static let unlockPIN = NSLocalizedString("unlock_with_pin", value: "Unlock with Passcode", comment: "Label for the button to unlock the device using a device passcode")
    static let sortEntries = NSLocalizedString("sort_entries", value: "Sort Logins", comment: "Title for the option sheet allowing users to sort logins")
    static let unnamedEntry = NSLocalizedString("unnamed_entry", value: "unnamed entry", comment: "Placeholder text for when there is no login name")
    static let username = NSLocalizedString("username", value: "Username", comment: "Section title text for username on the item detail screen")
    static let webAddress = NSLocalizedString("web_address", value: "Web Address", comment: "Section title text for the web address on the item detail screen")
    static let settingsSupportSectionHeader = NSLocalizedString("settings.support.header", value: "SUPPORT", comment: "Support section label in settings")
    static let settingsConfigurationSectionHeader = NSLocalizedString("settings.configuration.header", value: "CONFIGURATION", comment: "Configuration label in settings")
    static let settingsTitle = NSLocalizedString("settings.title", value: "Settings", comment: "Title on settings screen")
    static let settingsProvideFeedback = NSLocalizedString("settings.provideFeedback", value: "Send Feedback", comment: "Send feedback option in settings")
    static let faq = NSLocalizedString("settings.faq", value: "FAQ", comment: "FAQ option in settings")
    static let settingsAccount = NSLocalizedString("settings.account", value: "Account", comment: "Account option in settings")
    static let settingsAutoLock = NSLocalizedString("settings.autoLock", value: "Auto Lock", comment: "Auto Lock option in settings")
    static let settingsBrowser = NSLocalizedString("settings.browser", value: "Preferred Browser", comment: "Preferred Browser option in settings")
    static let autoLockOneMinute = NSLocalizedString("settings.autoLock.oneMinute", value: "1 minute", comment: "1 minute auto lock setting")
    static let autoLockFiveMinutes = NSLocalizedString("settings.autoLock.fiveMinutes", value: "5 minutes", comment: "5 minutes auto lock setting")
    static let autoLockFifteenMinutes = NSLocalizedString("settings.autoLock.fifteenMinutes", value: "15 minutes", comment: "15 minutes auto lock setting")
    static let autoLockThirtyMinutes = NSLocalizedString("settings.autoLock.thirtyMinutes", value: "30 minutes", comment: "30 minutes auto lock setting")
    static let autoLockOneHour = NSLocalizedString("settings.autoLock.oneHour", value: "1 hour", comment: "1 hour auto lock setting")
    static let autoLockTwelveHours = NSLocalizedString("settings.autoLock.twelveHour", value: "12 hours", comment: "12 hours auto lock setting")
    static let autoLockTwentyFourHours = NSLocalizedString("settings.autoLock.twentyFourHour", value: "24 hours", comment: "24 hours auto lock setting")
    static let autoLockNever = NSLocalizedString("settings.autoLock.never", value: "Never", comment: "Never")
    static let autoLockHeader = NSLocalizedString("settings.autoLock.header", value: "Select when to lock after a period of inactivity", comment: "Header displayed above auto lock settings.")
    static let browserHeader = NSLocalizedString("settings.browser.header", value: "Select which browser use with Lockwise", comment: "Header displayed above browser choice settings.")
    static let settingsBrowserChrome = NSLocalizedString("settings.browser.chrome", value: "Google Chrome", comment: "Chrome Browser")
    static let settingsBrowserFirefox = NSLocalizedString("settings.browser.firefox", value: "Firefox", comment: "Firefox Browser")
    static let settingsBrowserFocus = NSLocalizedString("settings.browser.focus", value: "Firefox Focus", comment: "Focus Browser")
    static let settingsBrowserKlar = NSLocalizedString("settings.browser.klar", value: "Firefox Klar", comment: "Klar Browser")
    static let settingsBrowserSafari = NSLocalizedString("settings.browser.safari", value: "Safari", comment: "Safari Browser")
    static let settingsUsageData = NSLocalizedString("settings.usageData", value: "Send Usage Data", comment: "Setting to send usage data")
    static let settingsUsageDataSubtitle = NSLocalizedString("settings.usageData.subtitle", value: "Mozilla strives to only collect what we need to provide and improve %@ for everyone. ", comment: "The subtitle for the telemetry (data usage) setting explaining why and how Mozilla collects data. %@ will be replaced with the application name")
    static let settingsAppVersion = NSLocalizedString("settings.appVersion", value: "App Version", comment: "App Version setting label")
    static let settingsAutoFillSettings = NSLocalizedString("settings.autoFillSettings", value: "AutoFill Instructions", comment: "Label to link to instructions about setting up AutoFill. AutoFill should be localized to match the proper name for Apple’s system feature")
    static let learnMore = NSLocalizedString("settings.learnMore", value: "Learn More", comment: "Label for link to learn more")
    static let notUsingPasscode = NSLocalizedString("not_using_passcode", value: "You’re not using a passcode.", comment: "Title for dialog box with passcode setting information")
    static let passcodeInformation = NSLocalizedString("passcode_info", value: "You should use a passcode to lock your device. Without a passcode, anyone who has your device can access the information saved here.", comment: "Informative text about the security need for a passcode")
    static let passcodeDetailInformation = NSLocalizedString("passcode_detail_information", value: "In order to lock %@, a passcode must be set up on your device. Without a passcode, anyone who has your device can access the information saved here.", comment: "Message for dialog box with passcode reminder. %@ will be replaced with the application name")
    static let skip = NSLocalizedString("skip", value: "Skip", comment: "Label for button allowing users to skip setting passcode or biometrics on device")
    static let setPasscode = NSLocalizedString("set_passcode", value: "Set Passcode", comment: "Label for button allowing users to go to passcode settings")
    static let sortOptionsAccessibilityID = NSLocalizedString("sorting_options", value: "Select options for sorting your list of logins (currently %@)", comment: "Accessibility identifier for the sorting options button. %@ will be replaced with the currently-set sort option")
    static let settingsAccessibilityID = NSLocalizedString("settings_button", value: "Settings", comment: "Accessibility identifier for the settings button")
    static let settingsGetSupport = NSLocalizedString("settings.getSupport", value: "Ask a Question", comment: "Support link to Discourse discussion forum")
    static let websiteCellAccessibilityLabel = NSLocalizedString("website_accessibility_instructions", value: "Web address: double tap to open in browser %@", comment: "Accessibility label and instructions for web address section of login details")
    static let usernameCellAccessibilityLabel = NSLocalizedString("username_accessibility_instructions", value: "Username: double tap to copy %@", comment: "Accessibility label and instructions for username section of login details. %@ will be replaced with the username value")
    static let passwordCellAccessibilityLabel = NSLocalizedString("password_accessibility_instructions", value: "Password: double tap to copy", comment: "Accessibility label and instructions for password section of login details. %@ will be replaced with the password value")
    static let syncingYourEntries = NSLocalizedString("syncing_entries", value: "Syncing your logins", comment: "Label and accessibility callout for Syncing your logins spinner and HUD")
    static let doneSyncingYourEntries = NSLocalizedString("done_syncing_entries", value: "Done Syncing your logins", comment: "Accessibility callout for finishing Syncing your logins")
    static let installBrowserAccessibilityLabel = NSLocalizedString("install_browser_prompt", value: "%@ disabled, install this browser to make it available", comment: "Accessibility instructions for disabled web browser options. %@ will be replaced with the browser name")
    static let onboardingSecurityPostfix = NSLocalizedString("onboarding.encryption", value: "256-bit encryption", comment: "Name of link to algorithm used by application for encryption")
    static let reauthenticationRequired = NSLocalizedString("reauth_required", value: "Reauthentication Required", comment: "Title of dialog box displayed when users need to reauthenticate")
    static let appUpdateDisclaimer = NSLocalizedString("app_update_explanation", value: "Due to a recent app update, we will need you to sign in again. Apologies for the inconvenience.", comment: "Message in dialog box when users need to reauthenticate explaining application update")
    static let continueText = NSLocalizedString("continue", value: "Continue", comment: "Button title when agreeing to proceed to access the application.")
    static let accessProduct = NSLocalizedString("welcome.accessProduct", value: "To use %@, you’ll need a Firefox Account with saved logins.", comment: "Access message displayed to user on welcome screen. %@ will be replaced with the application name")
    static let unlockAppButton = NSLocalizedString("welcome.unlockButton", value: "Unlock", comment: "Text on button to unlock app")
    static let unlinkAccountButton = NSLocalizedString("settings.unlinkAccount", value: "Disconnect %@", comment: "Text on button to unlink account. %@ will be replaced with the application name")
    static let disclaimerLabel = NSLocalizedString("settings.unlinkDisclaimer", value: "This removes synced logins from %@, but will not delete your logins from Firefox.", comment: "Label on account setting explaining unlink. %@ will be replaced with the application name")
    static let onboardingTitle = NSLocalizedString("onboarding.title", value: "Welcome to %@", comment: "Title on onboarding screen. %@ will be replaced with the application name")
    static let getStarted = NSLocalizedString("get.started", value: "Get Started", comment: "Title for the FxA login screen.")
    static let save = NSLocalizedString("save", value: "Save", comment: "This is the button title for the entry editor view")
    static let edit = NSLocalizedString("edit", value: "Edit", comment: "The button title allowing a user to access the item editor from the entry details view")
    static let name = NSLocalizedString("name", value: "Name", comment: "Row title for the `name` row of the item editor, describing what name is used when displaying the entry")
}

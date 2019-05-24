/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// swiftlint:disable line_length

import Foundation

class Localized {
    class string {
        static let enablingAutofill = NSLocalizedString("autofill.enabling", value: "Updating AutoFill…", comment: "Text displayed while AutoFill credentials are being populated. AutoFill should be localized to match the proper name for Apple’s system feature")
        static let completedEnablingAutofill = NSLocalizedString("autofill.finished_enabling", value: "Finished updating AutoFill", comment: "Accessibility notification when AutoFill is done being enabled")
        static let unlockPlaceholder = NSLocalizedString("unlock_placeholder", value: "This will unlock the app.", comment: "Placeholder text when the user’s email is unavailable while unlocking Lockbox, shown in Touch ID and passcode prompts")
        static let signInRequired = NSLocalizedString("autofill.signInRequired", value: "Sign in Required", comment: "Title for alert dialog explaining that a user must be signed in to use AutoFill.")
        static let signInRequiredBody = NSLocalizedString("autofill.signInRequiredBody", value: "You must be signed in to %@ before AutoFill will allow access to passwords within it.", comment: "Body for alert dialog explaining that a user must be signed in to use AutoFill. AutoFill should be localized to match the proper name for Apple's system feature. %1$@ and %2$@ will be replaced with the application name")
        static let ok = NSLocalizedString("ok", value: "OK", comment: "Ok button title")
        static let productName = NSLocalizedString("firefoxLockbox", value: "Firefox Lockwise", comment: "Product Name")
        static let productLabel = NSLocalizedString("lockwise", value: "Lockwise", comment: "This is the name displayed instead of Firefox Lockwise in some places")
        static let signIn = NSLocalizedString("signIn", value: "Sign In", comment: "Sign in button text")
        static let cancel = NSLocalizedString("cancel", value: "Cancel", comment: "Cancel button title")
        static let usernamePlaceholder = NSLocalizedString("username_placeholder", value: "(no username)", comment: "Placeholder text when there is no username. String should include appropriate open/close parenthetical or similar symbols to indicate this is a placeholder, not a real username.")
        static let searchYourEntries = NSLocalizedString("search.placeholder", value: "Search logins", comment: "Placeholder text for search field")
        static let emptyListPlaceholder = NSLocalizedString("list.empty", value: "%@ lets you access passwords you’ve already saved to Firefox. To view your logins here, you’ll need to sign in and sync with Firefox.", comment: "Label shown when there are no logins to list. %@ will be replaced with the application name")
    }
}

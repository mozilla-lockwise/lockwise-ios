/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TelemetryEventCategory {
    public static let action = "action"
}

class TelemetryEventMethod {
    public static let tap = "tap"
    public static let signin = "signin"
    public static let signin = "startup"
    public static let foreground = "foreground"
    public static let background = "background"
}

class TelemetryEventObject {
    public static let app = "app"
    public static let entryList = "entry_list"
    public static let settingsButton = "settings_button"
    public static let feedbackButton = "feedback_button"
    public static let faqButton = "faq_button"
    public static let copyUsernameButton = "copy_username_button"
    public static let copyPasswordButton = "copy_password_button"
    public static let viewPasswordButton = "view_password_button"
    public static let viewEntryButton = "view_entry_button"
    public static let entryCancelButton = "entry_cancel_button"
    public static let entryCopyUsernameButton = "entry_copy_username_button"
    public static let entryCopyPasswordButton = "entry_copy_password_button"
    public static let entryShowPasswordButton = "entry_view_password_button"

}

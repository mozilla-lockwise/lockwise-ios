/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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

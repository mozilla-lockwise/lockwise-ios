/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// swiftlint:disable line_length

import Foundation
import UIKit

extension Constant.string {
    static let enablingAutofill = NSLocalizedString("autofill.enabling", value: "Updating AutoFill…", comment: "Text displayed while AutoFill credentials are being populated. AutoFill should be localized to match the proper name for Apple’s system feature")
    static let completedEnablingAutofill = NSLocalizedString("autofill.finished_enabling", value: "Finished updating AutoFill", comment: "Accesibility notification when AutoFill is done being enabled")
    static let signInRequired = NSLocalizedString("autofill.signInRequired", value: "Sign in Required", comment: "Title for alert dialog explaining that a user must be signed in to use AutoFill.")
    static let signInRequiredBody = NSLocalizedString("autofill.signInRequiredBody", value: "You must be signed in to %@ before AutoFill will allow you to add passwords from %@. Once you have signed in, your entries will start appearing in AutoFill.", comment: "Body for alert dialog explaining that a user must be signed in to use AutoFill. AutoFill should be localized to match the proper name for Apple's system feature. %1$@ and %2$@ will be replaced with the application name")
}

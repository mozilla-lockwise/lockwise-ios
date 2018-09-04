/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

public let isRunningTest = NSClassFromString("XCTestCase") != nil

class Constant {
    class app {
        static let group = "group.org.mozilla.ios.Lockbox"
    }

    struct fxa {
        static let oldSyncScope = "https://identity.mozilla.com/apps/oldsync"
        static let lockboxScope = "https://identity.mozilla.com/apps/lockbox"
        static let profileScope = "profile"
        static let scopes = [oldSyncScope, lockboxScope, profileScope]
    }

    struct setting {
        static let defaultAutoLock = Setting.AutoLock.FiveMinutes
    }

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
    
    class string {
        static let enablingAutofill = NSLocalizedString("autofill.enabling", value: "Updating Autofill...", comment: "Text displayed while autofill credentials are being populated")
        static let completedEnablingAutofill = NSLocalizedString("autofill.finished_enabling", value: "Finished updating autofill", comment: "Accesibility notification when autofill is done being enabled")
        static let signInRequired = NSLocalizedString("autofill.signInRequired", value: "Sign in Required", comment: "Title for alert dialog explaining that a user must be signed in to use autofill")
        static let signInRequiredBody = NSLocalizedString("autofill.signInRequiredBody", value: "You must be signed in to %@ before AutoFill will allow you to add passwords from %@. Once you are signed in, go to your devices's Settings>Passwords & Accounts to add %@ to AutoFill", comment: "Body for alert dialog explaining that a user must be signed in to use autofill")
        static let ok = NSLocalizedString("ok", value: "OK", comment: "Ok button title")
        static let productName = NSLocalizedString("firefoxLockbox", value: "Firefox Lockbox", comment: "Product Name")
        static let signIn = NSLocalizedString("signIn", value: "Sign In", comment: "Sign in button text")
    }
}

enum UserDefaultKey: String {
    case autoLockTime, autoLockTimerDate

    static var allValues: [UserDefaultKey] = [.autoLockTime, .autoLockTimerDate]

    var defaultValue: Any? {
        switch self {
        case .autoLockTime:
            return Constant.setting.defaultAutoLock.rawValue
        case .autoLockTimerDate:
            return nil
        }
    }
}

enum KeychainKey: String {
    // note: these additional keys are holdovers from the previous Lockbox-owned style of
    // authentication
    case email, displayName, avatarURL, accountJSON

    static let allValues: [KeychainKey] = [.accountJSON, .email, .displayName, .avatarURL]
    
    static let oldAccountValues: [KeychainKey] = [.email, .displayName, .avatarURL]
}

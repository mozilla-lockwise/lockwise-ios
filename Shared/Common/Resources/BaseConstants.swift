/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

public let isRunningTest = NSClassFromString("XCTestCase") != nil

class Constant {
    class app {
        static let group = "group.org.mozilla.ios.Lockbox"
        static let syncTimeout: Double = 20
    }

    struct fxa {
        static let oldSyncScope = "https://identity.mozilla.com/apps/oldsync"
        static let lockboxScope = "https://identity.mozilla.com/apps/lockbox"
        static let profileScope = "profile"
        static let scopes = [oldSyncScope, lockboxScope, profileScope]
    }

    struct setting {
        static let defaultAutoLock = Setting.AutoLock.FiveMinutes
        static let defaultItemListSort = Setting.ItemListSort.alphabetically
        static let defaultRecordUsageData = true
        static let defaultForceLock = false
    }

    struct color {
        static let cellBorderGrey = UIColor(hex: 0xC8C7CC)
        static let viewBackground = UIColor(hex: 0xEDEDF0)
        static let lightGrey = UIColor(hex: 0xEFEFEF)
        static let systemLightGray = UIColor.lightGray
        static let lockBoxViolet = UIColor(red: 89, green: 42, blue: 203)
        static let lockBoxTeal = UIColor(hex: 0x00C8D7)
        static let settingsHeader = UIColor(hex: 0x737373)
        static let tableViewCellHighlighted = UIColor(red: 231, green: 223, blue: 255)
        static let buttonTitleColorNormalState = UIColor.white
        static let buttonTitleColorOtherState = UIColor(white: 1.0, alpha: 0.6)
        static let shadowColor = UIColor(red: 12, green: 12, blue: 13)
        static let videoBorderColor = UIColor(hex: 0xD7D7DB)
        static let helpTextBorderColor = UIColor(hex: 0xD8D7DE)
        static let navBackgroundColor = UIColor(red: 57, green: 52, blue: 115)
        static let navTextColor = UIColor(red: 237, green: 237, blue: 240)
        static let inactiveNavSearchBackgroundColor = UIColor(red: 43, green: 33, blue: 86)
        static let activeNavSearchBackgroundColor = UIColor(red: 39, green: 25, blue: 72)
        static let navSerachTextColor = UIColor.white
        static let navSearchPlaceholderTextColor = UIColor(white: 1.0, alpha: 0.8)
        static let disabledButtonTextColor = UIColor(red: 0.6119456291, green: 0.590236485, blue: 0.6646512747, alpha: 1)
        static let disabledButtonBackgroundColor = UIColor(red: 0.9608519673, green: 0.9606127143, blue: 0.9735968709, alpha: 1)
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
        static let enablingAutofill = NSLocalizedString("autofill.enabling", value: "Updating AutoFill…", comment: "Text displayed while AutoFill credentials are being populated. AutoFill should be localized to match the proper name for Apple’s system feature")
        static let completedEnablingAutofill = NSLocalizedString("autofill.finished_enabling", value: "Finished updating AutoFill", comment: "Accessibility notification when AutoFill is done being enabled")
        static let unlockPlaceholder = NSLocalizedString("unlock_placeholder", value: "This will unlock the app.", comment: "Placeholder text when the user’s email is unavailable while unlocking the app, shown in Touch ID and passcode prompts")
        static let signInRequired = NSLocalizedString("autofill.signInRequired", value: "Sign in Required", comment: "Title for alert dialog explaining that a user must be signed in to use AutoFill.")
        static let signInRequiredBody = NSLocalizedString("autofill.signInRequiredBody", value: "You must be signed in to %@ before AutoFill will allow access to passwords within it.", comment: "Body for alert dialog explaining that a user must be signed in to use AutoFill. AutoFill should be localized to match the proper name for Apple's system feature. %1$@ and %2$@ will be replaced with the application name")
        static let ok = NSLocalizedString("ok", value: "OK", comment: "Ok button title")
        static let productName = NSLocalizedString("firefoxLockbox", value: "Firefox Lockwise", comment: "Product Name")
        static let productLabel = NSLocalizedString("lockwise", value: "Lockwise", comment: "This is the name displayed instead of Firefox Lockwise in some places")
        static let signIn = NSLocalizedString("signIn", value: "Sign In", comment: "Sign in button text")
        static let cancel = NSLocalizedString("cancel", value: "Cancel", comment: "Cancel button title")
        static let delete = NSLocalizedString("delete", value: "Delete", comment: "Delete button title")
        static let usernamePlaceholder = NSLocalizedString("username_placeholder", value: "(no username)", comment: "Placeholder text when there is no username. String should include appropriate open/close parenthetical or similar symbols to indicate this is a placeholder, not a real username.")
        static let searchYourEntries = NSLocalizedString("search.placeholder", value: "Search logins", comment: "Placeholder text for search field")
        static let emptyListPlaceholder = NSLocalizedString("list.empty", value: "%@ lets you access passwords you’ve already saved to Firefox. To view your logins here, you’ll need to sign in and sync with Firefox.", comment: "Label shown when there are no logins to list. %@ will be replaced with the application name")
        static let syncTimedOut = NSLocalizedString("sync.timeout", value: "Sync timed out", comment: "This is the message displayed when syncing entries from the server times out")
    }
}

enum UserDefaultKey: String {
    case autoLockTime, autoLockTimerDate, itemListSort, recordUsageData, forceLock

    static var allValues: [UserDefaultKey] = [.autoLockTime, .autoLockTimerDate, .itemListSort, .recordUsageData, .forceLock]

    var defaultValue: Any? {
        switch self {
        case .autoLockTime:
            return Constant.setting.defaultAutoLock.rawValue
        case .recordUsageData:
            return Constant.setting.defaultRecordUsageData
        case .autoLockTimerDate:
            return nil
        case .itemListSort:
            return Constant.setting.defaultItemListSort.rawValue
        case .forceLock:
            return Constant.setting.defaultForceLock
        }
    }
}

enum KeychainKey: String {
    // note: these additional keys are holdovers from the previous Lockbox-owned style of
    // authentication
    case email
    case displayName
    case avatarURL
    case accountJSON
    case salt = "sqlcipher.key.logins.salt"
    case loginsKey = "sqlcipher.key.logins.db"
    
    public enum valueType {
        case account
        case database
        case all
    }

    static let accountValues: [KeychainKey] = [.accountJSON, .email, .displayName, .avatarURL]
    static let databaseValues: [KeychainKey] = [.salt, .loginsKey]
    static let allValues: [KeychainKey] = [.accountJSON, .email, .displayName, .avatarURL, .salt, .loginsKey]
    
    static let oldAccountValues: [KeychainKey] = [.email, .displayName, .avatarURL]
}

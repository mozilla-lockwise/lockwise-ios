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
        static let defaultItemListSort = Setting.ItemListSort.alphabetically
        static let defaultRecordUsageData = true
        static let defaultForceLock = false
    }

    struct color {
        static let cellBorderGrey = UIColor(hex: 0xC8C7CC)
        static let viewBackground = UIColor(hex: 0xEDEDF0)
        static let lightGrey = UIColor(hex: 0xEFEFEF)
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
    case email, displayName, avatarURL, accountJSON

    static let allValues: [KeychainKey] = [.accountJSON, .email, .displayName, .avatarURL]
    
    static let oldAccountValues: [KeychainKey] = [.email, .displayName, .avatarURL]
}

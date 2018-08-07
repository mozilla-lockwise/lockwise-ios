/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

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
    case email, displayName, avatarURL, accountJSON, appVersion

    static let allValues: [KeychainKey] = [.accountJSON, .email, .displayName, .avatarURL, .appVersion]
}

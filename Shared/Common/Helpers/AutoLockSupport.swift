/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class AutoLockSupport {
    static let shared = AutoLockSupport()

    private let userDefaultStore: UserDefaultStore
    private let userDefaults: UserDefaults

    init(userDefaultStore: UserDefaultStore = UserDefaultStore.shared,
         userDefaults: UserDefaults = UserDefaults(suiteName: Constant.app.group) ?? .standard) {
        self.userDefaultStore = userDefaultStore
        self.userDefaults = userDefaults
    }

    private func lockCurrentlyRequired() -> Bool {
        let autoLockTimerDate = userDefaults.double(forKey: UserDefaultKey.autoLockTimerDate.rawValue)
        let currentSystemTime = Date().timeIntervalSince1970

        return autoLockTimerDate >= currentSystemTime
    }

    private func storeAutoLockTimerDate(dateTime: Double) {
        userDefaults.set(dateTime, forKey: UserDefaultKey.autoLockTimerDate.rawValue)
    }
}

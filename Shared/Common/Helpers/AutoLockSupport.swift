/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

class AutoLockSupport {
    static let shared = AutoLockSupport()

    private let settingStore: SettingStore
    private let userDefaults: UserDefaults // issue #910
    private let disposeBag = DisposeBag()

    var lockCurrentlyRequired: Bool {
        let autoLockTimerDate = userDefaults.double(forKey: UserDefaultKey.autoLockTimerDate.rawValue)
        let currentSystemTime = Date.timeIntervalSinceReferenceDate

        return autoLockTimerDate <= currentSystemTime
    }

    init(settingStore: SettingStore = SettingStore.shared,
         userDefaults: UserDefaults = UserDefaults(suiteName: Constant.app.group) ?? .standard) {
        self.settingStore = settingStore
        self.userDefaults = userDefaults
    }

    func storeNextAutolockTime() {
        settingStore.autoLockTime
            .take(1)
            .subscribe(onNext: { [weak self] autoLockSetting in self?.updateNextLockTime(autoLockSetting)
            })
            .disposed(by: self.disposeBag)
    }

    func backDateNextLockTime() {
        storeAutoLockTimerDate(dateTime: 0)
    }

    func forwardDateNextLockTime() {
        storeAutoLockTimerDate(dateTime: Double.greatestFiniteMagnitude)
    }

    private func updateNextLockTime(_ autoLockTime: Setting.AutoLock) {
        if (autoLockTime == Setting.AutoLock.Never) {
            forwardDateNextLockTime()
        } else {
            storeAutoLockTimerDate(dateTime: Date.timeIntervalSinceReferenceDate + Double(autoLockTime.seconds))
        }
    }

    private func storeAutoLockTimerDate(dateTime: Double) {
        userDefaults.set(dateTime, forKey: UserDefaultKey.autoLockTimerDate.rawValue)
    }
}

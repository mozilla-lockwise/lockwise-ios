/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

/// Return the CLOCK_MONOTONIC_RAW clock as a TimeInterval. If for some reason the time could not be read, zero is returned.
func getRawMonotonicClock() -> TimeInterval {
    var uptime = timespec()
    if clock_gettime(CLOCK_MONOTONIC_RAW, &uptime) != 0 {
        return 0
    }
    return TimeInterval(uptime.tv_sec)
}

class AutoLockSupport {
    static let shared = AutoLockSupport()

    private let userDefaultStore: UserDefaultStore
    private let userDefaults: UserDefaults
    private let disposeBag = DisposeBag()

    var lockCurrentlyRequired: Bool {
        let autoLockTimerDate = userDefaults.double(forKey: UserDefaultKey.autoLockTimerDate.rawValue)
        let currentSystemTime = getRawMonotonicClock()

        return autoLockTimerDate <= currentSystemTime
    }

    init(userDefaultStore: UserDefaultStore = UserDefaultStore.shared,
         userDefaults: UserDefaults = UserDefaults(suiteName: Constant.app.group) ?? .standard) {
        self.userDefaultStore = userDefaultStore
        self.userDefaults = userDefaults
    }

    func storeNextAutolockTime() {
        userDefaultStore.autoLockTime
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
            storeAutoLockTimerDate(dateTime: getRawMonotonicClock() + Double(autoLockTime.seconds))
        }
    }

    private func storeAutoLockTimerDate(dateTime: Double) {
        userDefaults.set(dateTime, forKey: UserDefaultKey.autoLockTimerDate.rawValue)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

class UserDefaultStore: BaseUserDefaultStore {
    static let shared = UserDefaultStore()

    public var preferredBrowser: Observable<Setting.PreferredBrowser> {
        return self.userDefaults.onPreferredBrowser
    }

    override func initialized() {
        self.dispatcher.register
                .filterByType(class: SettingAction.self)
                .subscribe(onNext: { action in
                    switch action {
                    case .autoLockTime(let timeout):
                        self.userDefaults.set(timeout.rawValue, forKey: UserDefaultKey.autoLockTime.rawValue)
                    case .preferredBrowser(let browser):
                        self.userDefaults.set(browser.rawValue, forKey: LocalUserDefaultKey.preferredBrowser.rawValue)
                    case .recordUsageData(let enabled):
                        self.userDefaults.set(enabled, forKey: LocalUserDefaultKey.recordUsageData.rawValue)
                    case .itemListSort(let sort):
                        self.userDefaults.set(sort.rawValue, forKey: UserDefaultKey.itemListSort.rawValue)
                    case .reset:
                        self.restoreDefaults()
                    }
                })
                .disposed(by: self.disposeBag)

        self.dispatcher.register
                .filterByType(class: LifecycleAction.self)
                .subscribe(onNext: { action in
                    guard case let .upgrade(previous, _) = action else {
                        return
                    }

                    if previous <= 2 {
                        self.readValuesFrom(UserDefaults.standard)
                    }
                })
                .disposed(by: self.disposeBag)

        self.loadInitialValues()
    }

    override func loadInitialValues() {
        super.loadInitialValues()

        for key in LocalUserDefaultKey.allValues {
            if self.userDefaults.value(forKey: key.rawValue) == nil {
                self.userDefaults.set(key.defaultValue, forKey: key.rawValue)
            }
        }
    }

    override func restoreDefaults() {
        super.restoreDefaults()

        for key in LocalUserDefaultKey.allValues {
            self.userDefaults.set(key.defaultValue, forKey: key.rawValue)
        }
    }
}

extension UserDefaultStore {
    private func readValuesFrom(_ userDefaults: UserDefaults) {
        for key in LocalUserDefaultKey.allValues {
            if let value = userDefaults.value(forKey: key.rawValue) {
                self.userDefaults.set(value, forKey: key.rawValue)
            }
        }

        for key in UserDefaultKey.allValues {
            if let value = userDefaults.value(forKey: key.rawValue) {
                self.userDefaults.set(value, forKey: key.rawValue)
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

enum UserDefaultKey: String {
    case autoLockTime, preferredBrowser, recordUsageData, autoLockTimerDate, itemListSort

    static var allValues: [UserDefaultKey] = [.autoLockTime, .preferredBrowser, .recordUsageData, .autoLockTimerDate, .itemListSort]
}

extension UserDefaultKey {
    var defaultValue: Any? {
        switch self {
        case .preferredBrowser:
            return Constant.setting.defaultPreferredBrowser.rawValue
        case .autoLockTime:
            return Constant.setting.defaultAutoLock.rawValue
        case .recordUsageData:
            return Constant.setting.defaultRecordUsageData
        case .itemListSort:
            return Constant.setting.defaultItemListSort.rawValue
        case .autoLockTimerDate:
            return nil
        }
    }
}

class UserDefaultStore {
    static let shared = UserDefaultStore()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let userDefaults: UserDefaults

    public var autoLockTime: Observable<Setting.AutoLock> {
        return self.userDefaults.onAutoLockTime
    }

    public var preferredBrowser: Observable<Setting.PreferredBrowser> {
        return self.userDefaults.onPreferredBrowser
    }

    public var recordUsageData: Observable<Bool> {
        return self.userDefaults.onRecordUsageData
    }

    public var itemListSort: Observable<Setting.ItemListSort> {
        return self.userDefaults.onItemListSort
    }

    init(dispatcher: Dispatcher = Dispatcher.shared,
         userDefaults: UserDefaults = UserDefaults.standard) {
        self.dispatcher = dispatcher
        self.userDefaults = userDefaults

        self.dispatcher.register
                .filterByType(class: SettingAction.self)
                .subscribe(onNext: { action in
                    switch action {
                    case .autoLockTime(let timeout):
                        self.userDefaults.set(timeout.rawValue, forKey: UserDefaultKey.autoLockTime.rawValue)
                    case .preferredBrowser(let browser):
                        self.userDefaults.set(browser.rawValue, forKey: UserDefaultKey.preferredBrowser.rawValue)
                    case .recordUsageData(let enabled):
                        self.userDefaults.set(enabled, forKey: UserDefaultKey.recordUsageData.rawValue)
                    case .itemListSort(let sort):
                        self.userDefaults.set(sort.rawValue, forKey: UserDefaultKey.itemListSort.rawValue)
                    case .reset:
                        self.restoreDefaults()
                    }
                })
                .disposed(by: self.disposeBag)

        self.loadInitialValues()
    }

    private func loadInitialValues() {
        for key in UserDefaultKey.allValues {
            if self.userDefaults.value(forKey: key.rawValue) == nil {
                self.userDefaults.set(key.defaultValue, forKey: key.rawValue)
            }
        }
    }

    private func restoreDefaults() {
        for key in UserDefaultKey.allValues {
            self.userDefaults.set(key.defaultValue, forKey: key.rawValue)
        }
    }
}

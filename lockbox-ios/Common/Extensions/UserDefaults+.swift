/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

extension UserDefaults {
    func on<T>(setting: UserDefaultKey, type: T.Type) -> Observable<T> {
        return self.rx.observe(type, setting.rawValue).filterNil()
    }
}

extension UserDefaults {
    var onAutoLockTime: Observable<Setting.AutoLock> {
        return self.on(setting: .autoLockTime, type: String.self)
                .map { Setting.AutoLock(rawValue: $0) ?? Constant.setting.defaultAutoLock }
    }

    var onPreferredBrowser: Observable<Setting.PreferredBrowser> {
        return self.on(setting: .preferredBrowser, type: String.self)
            .map { Setting.PreferredBrowser(rawValue: $0) ?? Constant.setting.defaultPreferredBrowser }
    }

    var onRecordUsageData: Observable<Bool> {
        return self.on(setting: .recordUsageData, type: Bool.self)
    }

    var onItemListSort: Observable<Setting.ItemListSort> {
        return self.on(setting: .itemListSort, type: String.self)
            .map { Setting.ItemListSort(rawValue: $0) ?? Constant.setting.defaultItemListSort }
    }
}

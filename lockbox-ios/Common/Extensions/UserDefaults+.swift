/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

extension UserDefaults {
    var onPreferredBrowser: Observable<Setting.PreferredBrowser> {
        return self.on(setting: LocalUserDefaultKey.preferredBrowser.rawValue, type: String.self)
            .map { Setting.PreferredBrowser(rawValue: $0) ?? Constant.setting.defaultPreferredBrowser }
    }

    var onRecordUsageData: Observable<Bool> {
        return self.on(setting: LocalUserDefaultKey.recordUsageData.rawValue, type: Bool.self)
    }

    var onItemListSort: Observable<Setting.ItemListSort> {
        return self.on(setting: LocalUserDefaultKey.itemListSort.rawValue, type: String.self)
            .map { Setting.ItemListSort(rawValue: $0) ?? Constant.setting.defaultItemListSort }
    }
}

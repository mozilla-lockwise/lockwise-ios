/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

extension UserDefaults {
    func on<T>(setting: SettingKey, type: T.Type) -> Observable<T> {
        return self.rx.observe(type, setting.rawValue).filterNil()
    }
}

extension UserDefaults {
    var onAutoLockTime: Observable<AutoLockSetting> {
        return self.on(setting: .autoLockTime, type: String.self)
                .map { AutoLockSetting(rawValue: $0) ?? Constant.setting.defaultAutoLockTimeout }
    }

    var onPreferredBrowser: Observable<PreferredBrowserSetting> {
        return self.on(setting: .preferredBrowser, type: String.self)
            .map { PreferredBrowserSetting(rawValue: $0) ?? Constant.setting.defaultPreferredBrowser }
    }

    var onRecordUsageData: Observable<Bool> {
        return self.on(setting: .recordUsageData, type: Bool.self)
    }
}

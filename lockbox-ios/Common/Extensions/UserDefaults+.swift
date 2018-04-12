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
    var onLock: Observable<Bool> {
        return self.on(setting: .locked, type: Bool.self)
    }

    var onBiometricsEnabled: Observable<Bool> {
        return self.on(setting: .biometricLogin, type: Bool.self)
    }

    var onAutoLockTime: Observable<AutoLockSetting> {
        return self.on(setting: .autoLockTime, type: String.self)
                .map { AutoLockSetting(rawValue: $0) ?? Constant.setting.defaultAutoLockTimeout }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

extension UserDefaults {
    func on<T>(setting: String, type: T.Type) -> Observable<T> {
        return self.rx.observe(type, setting).filterNil()
    }
}

extension UserDefaults {
    var onAutoLockTime: Observable<Setting.AutoLock> {
        return self.on(setting: UserDefaultKey.autoLockTime.rawValue, type: String.self)
                .map { Setting.AutoLock(rawValue: $0) ?? Constant.setting.defaultAutoLock }
    }
}

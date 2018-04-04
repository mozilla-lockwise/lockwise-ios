/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

extension UserDefaults {
    var onLock: Observable<Bool> {
        return self.rx.observe(Bool.self, SettingKey.locked.rawValue).filterNil()
    }
}

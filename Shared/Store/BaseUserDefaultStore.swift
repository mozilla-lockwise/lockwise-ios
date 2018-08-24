/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

class BaseUserDefaultStore {
    internal let disposeBag = DisposeBag()

    internal let dispatcher: Dispatcher
    internal let userDefaults: UserDefaults

    public var autoLockTime: Observable<Setting.AutoLock> {
        return self.userDefaults.onAutoLockTime
    }

    init(dispatcher: Dispatcher = Dispatcher.shared,
         sharedUserDefaults: UserDefaults = UserDefaults(suiteName: Constant.app.group) ?? UserDefaults.standard) {
        self.dispatcher = dispatcher
        self.userDefaults = sharedUserDefaults
        
        self.initialized()
    }

    internal func initialized() {
        fatalError("not implemented!")
    }

    internal func loadInitialValues() {
        for key in UserDefaultKey.allValues {
            if self.userDefaults.value(forKey: key.rawValue) == nil {
                self.userDefaults.set(key.defaultValue, forKey: key.rawValue)
            }
        }
    }

    internal func restoreDefaults() {
        for key in UserDefaultKey.allValues {
            self.userDefaults.set(key.defaultValue, forKey: key.rawValue)
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

extension UserDefaults {
    var onPreferredBrowser: Observable<Setting.PreferredBrowser> {
        return self.on(setting: LocalUserDefaultKey.preferredBrowser.rawValue, type: String.self)
            .map {
                guard let preferredBrowser = Setting.PreferredBrowser(rawValue: $0)
                    else { return Constant.setting.defaultPreferredBrowser }
                if preferredBrowser.canOpenBrowser() {
                    return preferredBrowser
                } else { return Constant.setting.defaultPreferredBrowser  }
        }
    }
}

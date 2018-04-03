/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum SettingAction: Action {
    case biometricLogin(enabled: Bool)
    case autoLock(timeout: AutoLockSetting)
}

extension SettingAction: Equatable {
    static func ==(lhs: SettingAction, rhs: SettingAction) -> Bool {
        switch (lhs, rhs) {
        case (.biometricLogin(let lhEnabled), .biometricLogin(let rhEnabled)):
            return lhEnabled == rhEnabled
        case (.autoLock(let lhTimeout), .autoLock(let rhTimeout)):
            return lhTimeout == rhTimeout
        default:
            return false
        }
    }
}

enum SettingKey: String {
    case biometricLogin, autoLock
}

class SettingActionHandler: ActionHandler {
    static let shared = SettingActionHandler()
    fileprivate var dispatcher: Dispatcher
    fileprivate var userDefaults: UserDefaults

    init(dispatcher: Dispatcher = Dispatcher.shared,
         userDefaults: UserDefaults = UserDefaults.standard) {
        self.dispatcher = dispatcher
        self.userDefaults = userDefaults
    }

    func invoke(_ action: SettingAction) {
        switch action {
        case .biometricLogin(let enabled):
            self.userDefaults.set(enabled, forKey: SettingKey.biometricLogin.rawValue)
        case .autoLock(let timeout):
            self.userDefaults.set(timeout.rawValue, forKey: SettingKey.autoLock.rawValue)
        }

        // purely for telemetry, no app functionality depends on this
        self.dispatcher.dispatch(action: action)
    }
}

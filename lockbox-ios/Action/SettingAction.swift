/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum SettingAction: Action {
    case biometricLogin(enabled: Bool)
    case autoLockTime(timeout: AutoLockSetting)
    case visualLock(locked: Bool)
    case reset
}

extension SettingAction: Equatable {
    static func ==(lhs: SettingAction, rhs: SettingAction) -> Bool {
        switch (lhs, rhs) {
        case (.biometricLogin(let lhEnabled), .biometricLogin(let rhEnabled)):
            return lhEnabled == rhEnabled
        case (.autoLockTime(let lhTimeout), .autoLockTime(let rhTimeout)):
            return lhTimeout == rhTimeout
        case (.visualLock(let lhLocked), .visualLock(let rhLocked)):
            return lhLocked == rhLocked
        case (.reset, .reset):
            return true
        default:
            return false
        }
    }
}

enum SettingKey: String {
    case biometricLogin, autoLockTime, locked
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
        case .autoLockTime(let timeout):
            self.userDefaults.set(timeout.rawValue, forKey: SettingKey.autoLockTime.rawValue)
        case .visualLock(let locked):
            self.userDefaults.set(locked, forKey: SettingKey.locked.rawValue)
        case .reset:
            self.userDefaults.set(Constant.setting.defaultBiometricLockEnabled,
                    forKey: SettingKey.biometricLogin.rawValue)
            self.userDefaults.set(Constant.setting.defaultAutoLockTimeout.rawValue,
                    forKey: SettingKey.autoLockTime.rawValue)
            self.userDefaults.set(Constant.setting.defaultLockedState,
                    forKey: SettingKey.locked.rawValue)
        }

        // purely for telemetry, no app functionality depends on this
        self.dispatcher.dispatch(action: action)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum SettingAction: Action {
    case biometricLogin(enabled: Bool)
    case autoLock(timeout: AutoLockSetting)
    case reset
    case preferredBrowser(browser: PreferredBrowserSetting)
}

extension SettingAction: Equatable {
    static func ==(lhs: SettingAction, rhs: SettingAction) -> Bool {
        switch (lhs, rhs) {
        case (.biometricLogin(let lhEnabled), .biometricLogin(let rhEnabled)):
            return lhEnabled == rhEnabled
        case (.autoLock(let lhTimeout), .autoLock(let rhTimeout)):
            return lhTimeout == rhTimeout
        case (.preferredBrowser(let lhBrowser), .preferredBrowser(let rhBrowser)):
            return lhBrowser == rhBrowser
        case (.reset, .reset):
            return true
        default:
            return false
        }
    }
}

enum SettingKey: String {
    case biometricLogin, autoLock, preferredBrowser
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
        case .preferredBrowser(let browser):
            self.userDefaults.set(browser.rawValue, forKey: SettingKey.preferredBrowser.rawValue)
        case .reset:
            self.userDefaults.set(Constant.setting.defaultBiometricLockEnabled,
                    forKey: SettingKey.biometricLogin.rawValue)
            self.userDefaults.set(Constant.setting.defaultAutoLockTimeout.rawValue,
                    forKey: SettingKey.autoLock.rawValue)
        }

        // purely for telemetry, no app functionality depends on this
        self.dispatcher.dispatch(action: action)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

enum SettingAction: Action {
    case autoLockTime(timeout: AutoLockSetting)
    case reset
    case preferredBrowser(browser: PreferredBrowserSetting)
    case recordUsageData(enabled: Bool)
    case itemListSort(sort: ItemListSortSetting)
}

extension SettingAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        return .settingChanged
    }

    var eventObject: TelemetryEventObject {
        switch self {
        case .autoLockTime:
            return .settingsAutolockTime
        case .preferredBrowser:
            return .settingsPreferredBrowser
        case .reset:
            return .settingsReset
        case .recordUsageData:
            return .settingsRecordUsageData
        case .itemListSort:
            return .settingsItemListSort
        }
    }

    var value: String? {
        switch self {
        case .autoLockTime(let timeout):
            let timeoutString = String(timeout.rawValue)
            return timeoutString
        case .preferredBrowser(let browser):
            let browserString = String(browser.rawValue)
            return browserString
        case .reset:
            return nil
        case .recordUsageData(let enabled):
            let enabledString = String(enabled)
            return enabledString
        case .itemListSort(let sort):
            return sort == .alphabetically ?
                ItemListSortSetting.alphabetically.rawValue : ItemListSortSetting.recentlyUsed.rawValue
        }
  }

    var extras: [String: Any?]? {
        return nil
    }
}

extension SettingAction: Equatable {
    static func ==(lhs: SettingAction, rhs: SettingAction) -> Bool {
        switch (lhs, rhs) {
        case (.autoLockTime(let lhTimeout), .autoLockTime(let rhTimeout)):
            return lhTimeout == rhTimeout
        case (.preferredBrowser(let lhBrowser), .preferredBrowser(let rhBrowser)):
            return lhBrowser == rhBrowser
        case (.recordUsageData(let lhEnabled), .recordUsageData(let rhEnabled)):
            return lhEnabled == rhEnabled
        case (.itemListSort(let lhSort), .itemListSort(let rhSort)):
            return lhSort == rhSort
        case (.reset, .reset):
            return true
        default:
            return false
        }
    }
}

enum SettingKey: String {
    case autoLockTime, preferredBrowser, recordUsageData, autoLockTimerDate, itemListSort
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
        case .autoLockTime(let timeout):
            self.userDefaults.set(timeout.rawValue, forKey: SettingKey.autoLockTime.rawValue)
        case .preferredBrowser(let browser):
            self.userDefaults.set(browser.rawValue, forKey: SettingKey.preferredBrowser.rawValue)
        case .recordUsageData(let enabled):
            self.userDefaults.set(enabled, forKey: SettingKey.recordUsageData.rawValue)
        case .reset:
            self.userDefaults.set(Constant.setting.defaultAutoLockTimeout.rawValue,
                                  forKey: SettingKey.autoLockTime.rawValue)
            self.userDefaults.set(Constant.setting.defaultPreferredBrowser.rawValue,
                                  forKey: SettingKey.preferredBrowser.rawValue)
            self.userDefaults.set(Constant.setting.defaultRecordUsageData,
                                  forKey: SettingKey.recordUsageData.rawValue)
            self.userDefaults.set(Constant.setting.defaultItemListSort.rawValue,
                                  forKey: SettingKey.itemListSort.rawValue)
        case .itemListSort(let sort):
            self.userDefaults.set(sort.rawValue, forKey: SettingKey.itemListSort.rawValue)
        }

        // purely for telemetry, no app functionality depends on this
        self.dispatcher.dispatch(action: action)
    }
}

enum ItemListSortSetting: String {
    case alphabetically
    case recentlyUsed
}

enum AutoLockSetting: String {
    case OneMinute
    case FiveMinutes
    case OneHour
    case TwelveHours
    case TwentyFourHours
    case Never

    func toString() -> String {
        switch self {
        case .FiveMinutes:
            return Constant.string.autoLockFiveMinutes
        case .Never:
            return Constant.string.autoLockNever
        case .OneHour:
            return Constant.string.autoLockOneHour
        case .OneMinute:
            return Constant.string.autoLockOneMinute
        case .TwelveHours:
            return Constant.string.autoLockTwelveHours
        case .TwentyFourHours:
            return Constant.string.autoLockTwentyFourHours
        }
    }
}

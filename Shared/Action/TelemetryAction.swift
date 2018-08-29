/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Telemetry
import RxSwift
import RxCocoa

protocol TelemetryAction: Action {
    var eventMethod: TelemetryEventMethod { get }
    var eventObject: TelemetryEventObject { get }
    var value: String? { get }
    var extras: [String: Any?]? { get }
}

enum TelemetryEventCategory: String {
    case action
}

enum TelemetryEventMethod: String {
case tap, startup, foreground, background, settingChanged, show
}

enum TelemetryEventObject: String {
    case app = "app"
    case entryList = "entry_list"
    case entryDetail = "entry_detail"
    case learnMore = "learn_more"
    case revealPassword = "reveal_password"
    case entryCopyUsernameButton = "entry_copy_username_button"
    case entryCopyPasswordButton = "entry_copy_password_button"
    case settingsList = "settings_list"
    case settingsAutolockTime = "settings_autolock_time"
    case settingsAutolock = "settings_autolock"
    case settingsReset = "settings_reset"
    case settingsPreferredBrowser = "settings_preferred_browser"
    case settingsRecordUsageData = "settings_record_usage_data"
    case settingsAccount = "settings_account"
    case settingsItemListSort = "settings_item_list_sort"
    case settingsFaq = "settings_faq"
    case settingsProvideFeedback = "settings_provide_feedback"
    case settingsGetSupport = "settings_get_support"
    case loginWelcome = "login_welcome"
    case loginFxa = "login_fxa"
    case loginOnboardingConfirmation = "login_onboarding_confirmation"
    case loginLearnMore = "login_learn_more"
}

enum ExtraKey: String {
    case fxauid, itemid, error
}

class TelemetryActionHandler: ActionHandler {
    static let shared = TelemetryActionHandler()

    private let telemetry: Telemetry

    init(telemetry: Telemetry = Telemetry.default) {
        self.telemetry = telemetry

        let telemetryConfig = self.telemetry.configuration
        telemetryConfig.appName = "Lockbox"
        telemetryConfig.userDefaultsSuiteName = self.sharedContainerIdentifier
        telemetryConfig.appVersion = self.shortVersion

#if DEBUG
        telemetryConfig.isCollectionEnabled = false
        telemetryConfig.isUploadEnabled = false
        telemetryConfig.updateChannel = "debug"
#else
        telemetryConfig.isCollectionEnabled = true
        telemetryConfig.isUploadEnabled = true
        telemetryConfig.updateChannel = "release"
#endif

        // todo: get telemetry-ios PR merged so that we can have a custom PingBuilder for Lockbox
        self.telemetry.add(pingBuilderType: FocusEventPingBuilder.self)
    }

    lazy var telemetryActionListener: AnyObserver<TelemetryAction> = {
        return Binder(self) { target, action in
            target.telemetry.recordEvent(
                    category: TelemetryEventCategory.action.rawValue,
                    method: action.eventMethod.rawValue,
                    object: action.eventObject.rawValue,
                    value: action.value,
                    extras: action.extras
            )
        }.asObserver()
    }()
}

extension TelemetryActionHandler {
    fileprivate var sharedContainerIdentifier: String {
        return "group." + self.baseBundleIdentifier
    }

    fileprivate var baseBundleIdentifier: String {
        let bundle = Bundle.main
        let packageType = bundle.object(forInfoDictionaryKey: "CFBundlePackageType") as? NSString ?? ""
        let baseBundleIdentifier = bundle.bundleIdentifier!

        if packageType == "XPC!" {
            let components = baseBundleIdentifier.components(separatedBy: ".")
            return components[0..<components.count - 1].joined(separator: ".")
        }

        return baseBundleIdentifier
    }

    fileprivate var productName: String {
        return Bundle.main.infoDictionary?["CFBundleName"] as? String ?? ""
    }

    fileprivate var shortVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
}

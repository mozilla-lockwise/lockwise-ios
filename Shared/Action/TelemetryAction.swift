/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Glean
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
case tap, startup, foreground, background, settingChanged, show, canceled, login_selected, autofill_locked, autofill_unlocked, refresh, autofill_clear, shutdown, dnd, update_credentials, lock, unlock, reset, sync, touch, delete, sync_end, sync_timeout, sync_error, edit
}

enum TelemetryEventObject: String {
    case app = "app"
    case entryList = "entry_list"
    case entryDetail = "entry_detail"
    case entryEditor = "entry_editor"
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
    case settingsPrivacy = "settings_privacy"
    case loginWelcome = "login_welcome"
    case loginFxa = "login_fxa"
    case loginOnboardingConfirmation = "login_onboarding_confirmation"
    case loginLearnMore = "login_learn_more"
    case autofillOnboarding = "autofill_onboarding"
    case autofill = "autofill"
    case autofillSettingsInstructions = "autofill_instructions"
    case autofillOnboardingInstructions = "autofill_onboarding_instructions"
    case forceLock = "force_lock"
    case openInBrowser = "open_in_browser"
    case datastore = "datastore"
    case externalWebsite = "external_website"
    case edit = "edit_item"
}

enum ExtraKey: String {
    case fxauid, itemid, error
}

class GleanActionHandler: ActionHandler {
    private var disposeBag = DisposeBag()
    
    init(glean: Glean = Glean.shared,
         store: UserDefaultStore = UserDefaultStore.shared) {
        store.recordUsageData
            .observeOn(MainScheduler.instance)
            .subscribe(
            onNext: { uploadEnabled in
                // This is invoked once during the call to subscribe on
                // the main thread, so it will ensure that the Glean
                // requirement to call `setUploadEnabled()` before
                // `initialize()` is called below
                glean.setUploadEnabled(uploadEnabled)
            },
            onError: nil,
            onCompleted: nil,
            onDisposed: nil
        ).disposed(by: self.disposeBag)
                
        // Get legacy telemetry ID if not in extension
        #if LOCKWISE
            if let uuidString = UserDefaults.standard.string(forKey: "telemetry-key-prefix-clientId"), let uuid = UUID(uuidString: uuidString) {
                GleanMetrics.LegacyIds.clientId.set(uuid)
            }
        #endif
        
        // Since we are guaranteed to receive the invocation of
        // setUploadEnabled above, we can rely on getUploadEnabled to
        // retrieve the current telemetry preference state.
        glean.initialize(uploadEnabled: glean.getUploadEnabled())
    }
}

class TelemetryActionHandler: ActionHandler {
    private let telemetry: Telemetry
    private let accountStore: BaseAccountStore

    private var disposeBag = DisposeBag()

    private var profileUid: String?

    init(telemetry: Telemetry = Telemetry.default,
         accountStore: BaseAccountStore) {
        self.telemetry = telemetry
        self.accountStore = accountStore

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

        self.accountStore.profile.subscribe(onNext: { (profile) in
            self.profileUid = profile?.uid
        }).disposed(by: self.disposeBag)
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

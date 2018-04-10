/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LocalAuthentication

class SettingsPresenter {
    private var view: SettingsProtocol
    private var userDefaults: UserDefaults
    private var routeActionHandler: RouteActionHandler
    private var settingActionHandler: SettingActionHandler
    private var disposeBag = DisposeBag()

    lazy private(set) var onDone: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(MainRouteAction.list)
        }.asObserver()
    }()

    lazy private(set) var onSettingCellTapped: AnyObserver<SettingRouteAction?> = {
        return Binder(self) { target, action in
            guard let routeAction = action else {
                return
            }

            target.routeActionHandler.invoke(routeAction)
        }.asObserver()
    }()

    lazy var touchIdSetting = SwitchSettingCellConfiguration(text: Constant.string.settingsTouchId, routeAction: nil)
    lazy var faceIdSetting = SwitchSettingCellConfiguration(text: Constant.string.settingsFaceId, routeAction: nil)

    private var usesFaceId: Bool {
        let authContext = LAContext()
        var error: NSError?
        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if #available(iOS 11.0, *) {
                return authContext.biometryType == .faceID
            }
        }
        return false
    }

    init(view: SettingsProtocol,
         userDefaults: UserDefaults = UserDefaults.standard,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         settingActionHandler: SettingActionHandler = SettingActionHandler.shared) {
        self.view = view
        self.userDefaults = userDefaults
        self.routeActionHandler = routeActionHandler
        self.settingActionHandler = settingActionHandler
    }

    func switchChanged(row: Int, isOn: Bool) {
        settingActionHandler.invoke(.biometricLogin(enabled: isOn))
    }

    func onViewReady() {
        let biometricObserver = self.userDefaults.rx.observe(Bool.self, SettingKey.biometricLogin.rawValue)
        let autoLockObserver = self.userDefaults.rx.observe(String.self, SettingKey.autoLock.rawValue).filterNil()

        let settingsConfigDriver = Observable.combineLatest(biometricObserver, autoLockObserver)
                .map { (latest: (Bool?, String)) -> [SettingSectionModel] in
                    let autoLock = AutoLockSetting(rawValue: latest.1) ?? AutoLockSetting.FiveMinutes
                    return self.settingsWithBiometricLoginEnabled(latest.0 ?? false, autoLock: autoLock)
                }
                .asDriver(onErrorJustReturn: [])

        view.bind(items: settingsConfigDriver)
    }
}

extension SettingsPresenter {
    fileprivate func settingsWithBiometricLoginEnabled(_ enabled: Bool, autoLock: AutoLockSetting?)
        -> [SettingSectionModel] {
        let biometricSetting = usesFaceId ? faceIdSetting : touchIdSetting
        biometricSetting.isOn = enabled

        let autoLockSetting = SettingCellConfiguration(
            text: Constant.string.settingsAutoLock,
            routeAction: SettingRouteAction.autoLock)

        autoLockSetting.detailText = autoLock?.toString()

        return [
            SettingSectionModel(model: 0, items: [
                SettingCellConfiguration(
                        text: Constant.string.settingsProvideFeedback,
                        routeAction: SettingRouteAction.provideFeedback),
                SettingCellConfiguration(
                        text: Constant.string.settingsFaq,
                        routeAction: SettingRouteAction.faq),
                SettingCellConfiguration(
                        text: Constant.string.settingsEnableInBrowser,
                        routeAction: SettingRouteAction.enableInBrowser)
            ]),
            SettingSectionModel(model: 1, items: [
                SettingCellConfiguration(
                        text: Constant.string.settingsAccount,
                        routeAction: SettingRouteAction.account),
                biometricSetting,
                autoLockSetting
            ])
        ]
    }
}

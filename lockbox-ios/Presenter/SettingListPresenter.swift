/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LocalAuthentication

protocol SettingListViewProtocol: class {
    func bind(items: Driver<[SettingSectionModel]>)
    var onSignOut: ControlEvent<Void> { get }
}

class SettingListPresenter {
    weak private var view: SettingListViewProtocol?
    private let routeActionHandler: RouteActionHandler
    private let settingActionHandler: SettingActionHandler
    private let userDefaults: UserDefaults
    private let biometryManager: BiometryManager
    private let disposeBag = DisposeBag()

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

    init(view: SettingListViewProtocol,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         settingActionHandler: SettingActionHandler = SettingActionHandler.shared,
         userDefaults: UserDefaults = UserDefaults.standard,
         biometryManager: BiometryManager = BiometryManager()) {
        self.view = view
        self.routeActionHandler = routeActionHandler
        self.settingActionHandler = settingActionHandler
        self.userDefaults = userDefaults
        self.biometryManager = biometryManager
    }

    // todo: this should be an observer binding
    func switchChanged(row: Int, isOn: Bool) {
        self.settingActionHandler.invoke(.biometricLogin(enabled: isOn))
    }

    func onViewReady() {
        let settingsConfigDriver = Observable.combineLatest(self.userDefaults.onBiometricsEnabled, self.userDefaults.onAutoLockTime, self.userDefaults.onPreferredBrowser) // swiftlint:disable:this line_length
                .map { (latest: (Bool, AutoLockSetting, PreferredBrowserSetting)) -> [SettingSectionModel] in
                    return self.settingsWithBiometricLoginEnabled(
                        latest.0,
                        autoLock: latest.1,
                        preferredBrowser: latest.2)
                }
                .asDriver(onErrorJustReturn: [])

        self.view?.bind(items: settingsConfigDriver)

        self.view?.onSignOut
                .subscribe { _ in
                    self.settingActionHandler.invoke(SettingAction.visualLock(locked: true))
                    self.routeActionHandler.invoke(LoginRouteAction.welcome)
                }
                .disposed(by: self.disposeBag)
    }
}

extension SettingListPresenter {
    fileprivate func settingsWithBiometricLoginEnabled(_ enabled: Bool, autoLock: AutoLockSetting?, preferredBrowser: PreferredBrowserSetting) -> [SettingSectionModel] { // swiftlint:disable:this line_length
        let accountSettingSection = SettingSectionModel(model: 0, items: [
            SettingCellConfiguration(
                    text: Constant.string.settingsProvideFeedback,
                    routeAction: SettingRouteAction.provideFeedback),
            SettingCellConfiguration(
                    text: Constant.string.settingsFaq,
                    routeAction: SettingRouteAction.faq)
        ])

        var applicationConfigurationSection = SettingSectionModel(model: 1, items: [
            SettingCellConfiguration(
                    text: Constant.string.settingsAccount,
                    routeAction: SettingRouteAction.account)
        ])

        if self.biometryManager.usesFaceID || self.biometryManager.usesTouchID {
            let biometricSetting = self.biometryManager.usesFaceID ? faceIdSetting : touchIdSetting
            biometricSetting.isOn = enabled

            applicationConfigurationSection.items.append(biometricSetting)
        }

        let autoLockSetting = SettingCellConfiguration(
                text: Constant.string.settingsAutoLock,
                routeAction: SettingRouteAction.autoLock)
        autoLockSetting.detailText = autoLock?.toString()
        applicationConfigurationSection.items.append(autoLockSetting)

        let preferredBrowserSetting = SettingCellConfiguration(
            text: Constant.string.settingsBrowser,
            routeAction: SettingRouteAction.preferredBrowser)
        preferredBrowserSetting.detailText = preferredBrowser.toString()
        applicationConfigurationSection.items.append(preferredBrowserSetting)

        return [ accountSettingSection, applicationConfigurationSection ]
    }
}

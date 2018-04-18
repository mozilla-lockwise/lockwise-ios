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

    init(view: SettingListViewProtocol,
         userDefaults: UserDefaults = UserDefaults.standard,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         settingActionHandler: SettingActionHandler = SettingActionHandler.shared) {
        self.view = view
        self.userDefaults = userDefaults
        self.routeActionHandler = routeActionHandler
        self.settingActionHandler = settingActionHandler
    }

    // todo: this should be an observer binding
    func switchChanged(row: Int, isOn: Bool) {
        self.settingActionHandler.invoke(.biometricLogin(enabled: isOn))
    }

    func onViewReady() {
        let settingsConfigDriver = Observable.combineLatest(self.userDefaults.onBiometricsEnabled, self.userDefaults.onAutoLockTime) // swiftlint:disable:this line_length
                .map { (latest: (Bool, AutoLockSetting)) -> [SettingSectionModel] in
                    return self.settingsWithBiometricLoginEnabled(latest.0, autoLock: latest.1)
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
    fileprivate func settingsWithBiometricLoginEnabled(_ enabled: Bool, autoLock: AutoLockSetting?) -> [SettingSectionModel] { // swiftlint:disable:this line_length
        let biometricSetting = LAContext.usesFaceId ? faceIdSetting : touchIdSetting
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
                autoLockSetting,
                SettingCellConfiguration(
                    text: Constant.string.settingsBrowser,
                    routeAction: SettingRouteAction.preferredBrowser)
            ])
        ]
    }
}

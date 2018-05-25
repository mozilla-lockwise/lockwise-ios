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
    var hideLockNow: AnyObserver<Bool> { get }
}

class SettingListPresenter {
    weak private var view: SettingListViewProtocol?
    private let routeActionHandler: RouteActionHandler
    private let settingActionHandler: SettingActionHandler
    private let dataStoreActionHandler: DataStoreActionHandler
    private let userDefaults: UserDefaults
    private let biometryManager: BiometryManager
    private let disposeBag = DisposeBag()

    lazy private(set) var onDone: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(MainRouteAction.list)
        }.asObserver()
    }()

    lazy private(set) var onSettingCellTapped: AnyObserver<RouteAction?> = {
        return Binder(self) { target, action in
            guard let routeAction = action else {
                return
            }

            target.routeActionHandler.invoke(routeAction)
        }.asObserver()
    }()

    lazy private(set) var onUsageDataSettingChanged: AnyObserver<Bool> = {
        return Binder(self) { target, enabled in
            target.settingActionHandler.invoke(SettingAction.recordUsageData(enabled: enabled))
        }.asObserver()
    }()

    init(view: SettingListViewProtocol,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         settingActionHandler: SettingActionHandler = SettingActionHandler.shared,
         dataStoreActionHandler: DataStoreActionHandler = DataStoreActionHandler.shared,
         userDefaults: UserDefaults = UserDefaults.standard,
         biometryManager: BiometryManager = BiometryManager()) {
        self.view = view
        self.routeActionHandler = routeActionHandler
        self.settingActionHandler = settingActionHandler
        self.dataStoreActionHandler = dataStoreActionHandler
        self.userDefaults = userDefaults
        self.biometryManager = biometryManager
    }

    func onViewReady() {
        let settingsConfigDriver = Observable.combineLatest(self.userDefaults.onAutoLockTime, self.userDefaults.onPreferredBrowser, self.userDefaults.onRecordUsageData) // swiftlint:disable:this line_length
                .map { (latest: (AutoLockSetting, PreferredBrowserSetting, Bool)) -> [SettingSectionModel] in
                    return self.getSettings(
                            autoLock: latest.0,
                            preferredBrowser: latest.1,
                            usageDataEnabled: latest.2)
                }
                .asDriver(onErrorJustReturn: [])

        self.view?.bind(items: settingsConfigDriver)

        self.view?.onSignOut
                .subscribe { _ in
                    self.dataStoreActionHandler.invoke(.lock)
                    self.routeActionHandler.invoke(LoginRouteAction.welcome)
                }
                .disposed(by: self.disposeBag)

        self.view?.hideLockNow.onNext(!self.biometryManager.deviceAuthenticationAvailable)
    }
}

extension SettingListPresenter {
    fileprivate func getSettings(
            autoLock: AutoLockSetting?,
            preferredBrowser: PreferredBrowserSetting,
            usageDataEnabled: Bool) -> [SettingSectionModel] {

        var supportSettingSection = SettingSectionModel(model: 0, items: [
            SettingCellConfiguration(
                    text: Constant.string.settingsProvideFeedback,
                    routeAction: ExternalWebsiteRouteAction(
                            urlString: Constant.app.provideFeedbackURL,
                            title: Constant.string.settingsProvideFeedback,
                            returnRoute: SettingRouteAction.list)),
            SettingCellConfiguration(
                    text: Constant.string.faq,
                    routeAction: ExternalWebsiteRouteAction(
                            urlString: Constant.app.faqURL,
                            title: Constant.string.faq,
                            returnRoute: SettingRouteAction.list))
        ])

        var applicationConfigurationSection = SettingSectionModel(model: 1, items: [
            SettingCellConfiguration(
                    text: Constant.string.settingsAccount,
                    routeAction: SettingRouteAction.account)
        ])

        if self.biometryManager.deviceAuthenticationAvailable {
            let autoLockSetting = SettingCellConfiguration(
                    text: Constant.string.settingsAutoLock,
                    routeAction: SettingRouteAction.autoLock)
            autoLockSetting.detailText = autoLock?.toString()
            applicationConfigurationSection.items.append(autoLockSetting)
        }

        let preferredBrowserSetting = SettingCellConfiguration(
                text: Constant.string.settingsBrowser,
                routeAction: SettingRouteAction.preferredBrowser)
        preferredBrowserSetting.detailText = preferredBrowser.toString()
        applicationConfigurationSection.items.append(preferredBrowserSetting)

        let usageDataSetting = SwitchSettingCellConfiguration(
                text: Constant.string.settingsUsageData,
                routeAction: ExternalWebsiteRouteAction(
                        urlString: Constant.app.privacyURL,
                        title: Constant.string.faq,
                        returnRoute: SettingRouteAction.list),
                isOn: usageDataEnabled,
                onChanged: self.onUsageDataSettingChanged)
        let subtitle = NSMutableAttributedString(
                string: Constant.string.settingsUsageDataSubtitle,
                attributes: [NSAttributedStringKey.foregroundColor: UIColor.gray])
        subtitle.append(NSAttributedString(
                string: Constant.string.learnMore,
                attributes: [NSAttributedStringKey.foregroundColor: Constant.color.lockBoxBlue]))
        usageDataSetting.subtitle = subtitle
        supportSettingSection.items.append(usageDataSetting)

        return [supportSettingSection, applicationConfigurationSection]
    }
}

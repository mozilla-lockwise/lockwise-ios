/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LocalAuthentication

protocol SettingListViewProtocol: class, AlertControllerView {
    func bind(items: Driver<[SettingSectionModel]>)
    var onSignOut: ControlEvent<Void> { get }
}

class SettingListPresenter {
    weak private var view: SettingListViewProtocol?
    private let dispatcher: Dispatcher
    private let userDefaultStore: UserDefaultStore
    private let biometryManager: BiometryManager
    private let disposeBag = DisposeBag()

    lazy private(set) var onDone: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: MainRouteAction.list)
        }.asObserver()
    }()

    lazy private(set) var onSettingCellTapped: AnyObserver<RouteAction?> = {
        return Binder(self) { target, action in
            guard let routeAction = action else {
                return
            }

            target.dispatcher.dispatch(action: routeAction)
        }.asObserver()
    }()

    lazy private(set) var onUsageDataSettingChanged: AnyObserver<Bool> = {
        return Binder(self) { target, enabled in
            target.dispatcher.dispatch(action: SettingAction.recordUsageData(enabled: enabled))
        }.asObserver()
    }()

    private var setPasscodeButtonObserver: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: SettingLinkAction.touchIDPasscode)
            }.asObserver()
    }

    private var passcodeButtonsConfiguration: [AlertActionButtonConfiguration] {
        return [
            AlertActionButtonConfiguration(
                title: Constant.string.cancel,
                tapObserver: nil,
                style: .cancel),
            AlertActionButtonConfiguration(
                title: Constant.string.setPasscode,
                tapObserver: self.setPasscodeButtonObserver,
                style: .default)
        ]
    }

    private var staticSupportSettingSection: SettingSectionModel {
        return SettingSectionModel(model: 0, items: [
            SettingCellConfiguration(
                    text: Constant.string.settingsProvideFeedback,
                    routeAction: ExternalWebsiteRouteAction(
                            urlString: Constant.app.provideFeedbackURL,
                            title: Constant.string.settingsProvideFeedback,
                            returnRoute: SettingRouteAction.list),
                            accessibilityId: "sendFeedbackSettingOption"),
            SettingCellConfiguration(
                    text: Constant.string.faq,
                    routeAction: ExternalWebsiteRouteAction(
                            urlString: Constant.app.faqURL,
                            title: Constant.string.faq,
                            returnRoute: SettingRouteAction.list),
                            accessibilityId: "faqSettingOption")
        ])
    }

    init(view: SettingListViewProtocol,
         dispatcher: Dispatcher = .shared,
         userDefaultStore: UserDefaultStore = .shared,
         biometryManager: BiometryManager = BiometryManager()) {
        self.view = view
        self.dispatcher = dispatcher
        self.userDefaultStore = userDefaultStore
        self.biometryManager = biometryManager
    }

    func onViewReady() {
        let settingsConfigDriver = Observable.combineLatest(
                        self.userDefaultStore.autoLockTime,
                        self.userDefaultStore.preferredBrowser,
                        self.userDefaultStore.recordUsageData
                )
                .map { (latest: (Setting.AutoLock, Setting.PreferredBrowser, Bool)) -> [SettingSectionModel] in
                    return self.getSettings(
                            autoLock: latest.0,
                            preferredBrowser: latest.1,
                            usageDataEnabled: latest.2)
                }
                .asDriver(onErrorJustReturn: [])

        self.view?.bind(items: settingsConfigDriver)

        self.view?.onSignOut
                .subscribe { _ in
                    if self.biometryManager.deviceAuthenticationAvailable {
                        self.dispatcher.dispatch(action: DataStoreAction.lock)
                        self.dispatcher.dispatch(action: LoginRouteAction.welcome)
                    } else {
                        self.view?.displayAlertController(
                            buttons: self.passcodeButtonsConfiguration,
                            title: Constant.string.notUsingPasscode,
                            message: Constant.string.passcodeDetailInformation,
                            style: .alert)
                    }
                }
                .disposed(by: self.disposeBag)
    }
}

extension SettingListPresenter {
    fileprivate func getSettings(
            autoLock: Setting.AutoLock?,
            preferredBrowser: Setting.PreferredBrowser,
            usageDataEnabled: Bool) -> [SettingSectionModel] {

        var applicationConfigurationSection = SettingSectionModel(model: 1, items: [
            SettingCellConfiguration(
                    text: Constant.string.settingsAccount,
                    routeAction: SettingRouteAction.account,
                    accessibilityId: "accountSettingOption")
        ])

        if self.biometryManager.deviceAuthenticationAvailable {
            let autoLockSetting = SettingCellConfiguration(
                    text: Constant.string.settingsAutoLock,
                    routeAction: SettingRouteAction.autoLock,
                    accessibilityId: "autoLockSettingOption")
            autoLockSetting.detailText = autoLock?.toString()
            applicationConfigurationSection.items.append(autoLockSetting)
        }

        let preferredBrowserSetting = SettingCellConfiguration(
                text: Constant.string.settingsBrowser,
                routeAction: SettingRouteAction.preferredBrowser,
                accessibilityId: "openWebSitesInSettingOption")
        preferredBrowserSetting.detailText = preferredBrowser.toString()
        applicationConfigurationSection.items.append(preferredBrowserSetting)

        let usageDataSetting = SwitchSettingCellConfiguration(
                text: Constant.string.settingsUsageData,
                routeAction: ExternalWebsiteRouteAction(
                        urlString: Constant.app.privacyURL,
                        title: Constant.string.learnMore,
                        returnRoute: SettingRouteAction.list),
                accessibilityId: "usageDataSettingOption",
                isOn: usageDataEnabled,
                onChanged: self.onUsageDataSettingChanged)
        let subtitle = NSMutableAttributedString(
                string: Constant.string.settingsUsageDataSubtitle,
                attributes: [NSAttributedString.Key.foregroundColor: UIColor.gray])
        subtitle.append(NSAttributedString(
                string: Constant.string.learnMore,
                attributes: [NSAttributedString.Key.foregroundColor: Constant.color.lockBoxBlue]))
        usageDataSetting.subtitle = subtitle
        usageDataSetting.accessibilityActions = [
            UIAccessibilityCustomAction(
                    name: Constant.string.learnMore,
                    target: self,
                    selector: #selector(self.learnMoreTapped))]

        var supportSettingSection = self.staticSupportSettingSection
        supportSettingSection.items.append(usageDataSetting)

        if let appVersion = Constant.app.appVersion {
            let appVersionSetting = SettingCellConfiguration(text: Constant.string.settingsAppVersion, routeAction: nil,
                accessibilityId: "appVersionSettingOption")
            appVersionSetting.detailText = appVersion
            supportSettingSection.items.append(appVersionSetting)
        }

        return [supportSettingSection, applicationConfigurationSection]
    }

    @objc private func learnMoreTapped() {
        self.onSettingCellTapped.onNext(
                ExternalWebsiteRouteAction(
                        urlString: Constant.app.faqURL,
                        title: Constant.string.faq,
                        returnRoute: SettingRouteAction.list
                ))
    }
}

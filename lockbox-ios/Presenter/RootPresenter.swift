/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import UIKit
import FxAClient
import AdjustSdk

protocol RootViewProtocol: class {
    func topViewIs<T: UIViewController>(_ type: T.Type) -> Bool
    func modalViewIs<T: UIViewController>(_ type: T.Type) -> Bool
    func mainStackIs<T: UINavigationController>(_ type: T.Type) -> Bool
    func modalStackIs<T: UINavigationController>(_ type: T.Type) -> Bool

    func startMainStack<T: UINavigationController>(_ type: T.Type)
    func startModalStack<T: UINavigationController>(_ navigationController: T)
    func dismissModals()

    func pushLoginView(view: LoginRouteAction)
    func pushMainView(view: MainRouteAction)
    func pushSettingView(view: SettingRouteAction)
}

struct OAuthProfile {
    let oauthInfo: OAuthInfo?
    let profile: Profile?
}

extension OAuthProfile: Equatable {
    static func ==(lh: OAuthProfile, rh: OAuthProfile) -> Bool {
        return// todo: update these when we can make profile and oauthinfo equatable
                (lh.profile == nil) == (rh.profile == nil) &&
                (lh.oauthInfo == nil) == (rh.oauthInfo == nil)
    }
}

class RootPresenter {
    private weak var view: RootViewProtocol?
    private let disposeBag = DisposeBag()

    fileprivate let dispatcher: Dispatcher
    fileprivate let routeStore: RouteStore
    fileprivate let dataStore: DataStore
    fileprivate let telemetryStore: TelemetryStore
    fileprivate let accountStore: AccountStore
    fileprivate let userDefaultStore: UserDefaultStore
    fileprivate let telemetryActionHandler: TelemetryActionHandler
    fileprivate let biometryManager: BiometryManager

    var fxa: FirefoxAccount?

    init(view: RootViewProtocol,
         dispatcher: Dispatcher = .shared,
         routeStore: RouteStore = RouteStore.shared,
         dataStore: DataStore = DataStore.shared,
         telemetryStore: TelemetryStore = TelemetryStore.shared,
         accountStore: AccountStore = AccountStore.shared,
         userDefaultStore: UserDefaultStore = .shared,
         telemetryActionHandler: TelemetryActionHandler = TelemetryActionHandler.shared,
         biometryManager: BiometryManager = BiometryManager()
    ) {
        self.view = view
        self.dispatcher = dispatcher
        self.routeStore = routeStore
        self.dataStore = dataStore
        self.telemetryStore = telemetryStore
        self.accountStore = accountStore
        self.userDefaultStore = userDefaultStore
        self.telemetryActionHandler = telemetryActionHandler
        self.biometryManager = biometryManager

        // todo: update tests with populated oauth and profile info
        Observable.combineLatest(self.accountStore.oauthInfo, self.accountStore.profile)
                .map { OAuthProfile(oauthInfo: $0.0, profile: $0.1) }
                .distinctUntilChanged()
                .bind { latest in
                    if let oauthInfo = latest.oauthInfo,
                        let profile = latest.profile {
                        self.dataStoreActionHandler.invoke(.updateCredentials(oauthInfo: oauthInfo, fxaProfile: profile))
                    } else if latest.oauthInfo == nil && latest.profile == nil {
                        self.routeActionHandler.invoke(LoginRouteAction.welcome)
                        self.dataStoreActionHandler.invoke(.reset)
                    }
                }
                .disposed(by: self.disposeBag)

        Observable.combineLatest(self.dataStore.locked, self.accountStore.hasOldAccountInformation, self.dataStore.storageState)
                .filter { !$0.1 && $0.2 != LoginStoreState.Unprepared }
                .map { $0.0 }
                .distinctUntilChanged()
                .subscribe(onNext: { locked in
                    let route: RouteAction = locked ? LoginRouteAction.welcome : MainRouteAction.list

                    self.routeActionHandler.invoke(route)
                })
                .disposed(by: self.disposeBag)

        self.dispatcher.dispatch(action: OnboardingStatusAction(onboardingInProgress: false))
        self.startTelemetry()
        self.startAdjust()
    }

    func onViewReady() {
        self.routeStore.onRoute
                .filterByType(class: LoginRouteAction.self)
                .asDriver(onErrorJustReturn: .welcome)
                .drive(showLogin)
                .disposed(by: disposeBag)

        Observable.combineLatest(self.routeStore.onRoute, self.routeStore.onboarding)
                .filter { !$0.1 }
                .map { $0.0 }
                .filterByType(class: MainRouteAction.self)
                .asDriver(onErrorJustReturn: .list)
                .drive(showList)
                .disposed(by: disposeBag)

        Observable.combineLatest(self.routeStore.onRoute, self.routeStore.onboarding)
                .filter { !$0.1 }
                .map { $0.0 }
                .filterByType(class: SettingRouteAction.self)
                .asDriver(onErrorJustReturn: .list)
                .drive(self.showSetting)
                .disposed(by: self.disposeBag)

        self.routeStore.onRoute
                .filterByType(class: ExternalWebsiteRouteAction.self)
                .asDriver(onErrorJustReturn: ExternalWebsiteRouteAction(
                        urlString: "",
                        title: "Error",
                        returnRoute: MainRouteAction.list))
                .drive(self.showExternalWebsite)
                .disposed(by: self.disposeBag)
    }

    lazy private var showLogin: AnyObserver<LoginRouteAction> = { [unowned self] in
        return Binder(self) { target, loginAction in
            guard let view = target.view else {
                return
            }

            view.dismissModals()

            if !view.mainStackIs(LoginNavigationController.self) {
                view.startMainStack(LoginNavigationController.self)
            }

            switch loginAction {
            case .welcome:
                if !view.topViewIs(WelcomeView.self) {
                    view.pushLoginView(view: .welcome)
                }
            case .fxa:
                if !view.topViewIs(FxAView.self) {
                    view.pushLoginView(view: .fxa)
                }
            case .onboardingConfirmation:
                if !view.topViewIs(OnboardingConfirmationView.self) {
                    view.pushLoginView(view: .onboardingConfirmation)
                }
            }
        }.asObserver()
    }()

    lazy private var showList: AnyObserver<MainRouteAction> = { [unowned self] in
        return Binder(self) { target, mainAction in
            guard let view = target.view else {
                return
            }

            view.dismissModals()

            if !view.mainStackIs(MainNavigationController.self) {
                view.startMainStack(MainNavigationController.self)
            }

            switch mainAction {
            case .list:
                if !view.topViewIs(ItemListView.self) {
                    view.pushMainView(view: .list)
                }
            case .detail(let id):
                if !view.topViewIs(ItemDetailView.self) {
                    view.pushMainView(view: .detail(itemId: id))
                }
            }
        }.asObserver()
    }()

    lazy private var showSetting: AnyObserver<SettingRouteAction> = { [unowned self] in
        return Binder(self) { target, settingAction in
            guard let view = target.view else {
                return
            }

            view.dismissModals()

            if !view.mainStackIs(SettingNavigationController.self) {
                view.startMainStack(SettingNavigationController.self)
            }

            switch settingAction {
            case .list:
                if !view.topViewIs(SettingListView.self) {
                    view.pushSettingView(view: .list)
                }
            case .account:
                if !view.topViewIs(AccountSettingView.self) {
                    view.pushSettingView(view: .account)
                }
            case .autoLock:
                if !view.topViewIs(AutoLockSettingView.self) {
                    view.pushSettingView(view: .autoLock)
                }
            case .preferredBrowser:
                if !view.topViewIs(PreferredBrowserSettingView.self) {
                    view.pushSettingView(view: .preferredBrowser)
                }
            }
        }.asObserver()
    }()

    lazy private var showExternalWebsite: AnyObserver<ExternalWebsiteRouteAction> = { [unowned self] in
        return Binder(self) { target, externalSiteAction in
            guard let view = target.view else {
                return
            }

            if !view.modalStackIs(ExternalWebsiteNavigationController.self) {
                view.startModalStack(
                        ExternalWebsiteNavigationController(
                                urlString: externalSiteAction.urlString,
                                title: externalSiteAction.title,
                                returnRoute: externalSiteAction.returnRoute
                        )
                )
            }
        }.asObserver()
    }()
}

extension RootPresenter {
    fileprivate func startTelemetry() {
        Observable.combineLatest(self.telemetryStore.telemetryFilter, self.userDefaultStore.recordUsageData)
                .filter { $0.1 }
                .map { $0.0 }
                .bind(to: self.telemetryActionHandler.telemetryActionListener)
                .disposed(by: self.disposeBag)
    }

    fileprivate func startAdjust() {
        self.userDefaultStore.recordUsageData.subscribe(onNext: { enabled in
            Adjust.setEnabled(enabled)
        }).disposed(by: self.disposeBag)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import UIKit

protocol RootViewProtocol: class {
    func topViewIs<T: UIViewController>(_ type: T.Type) -> Bool
    func modalViewIs<T: UIViewController>(_ type: T.Type) -> Bool
    func mainStackIs<T: UINavigationController>(_ type: T.Type) -> Bool
    func modalStackIs<T: UINavigationController>(_ type: T.Type) -> Bool

    func startMainStack<T: UINavigationController>(_ type: T.Type)
    func startModalStack<T: UINavigationController>(_ type: T.Type)
    func dismissModals()

    func pushLoginView(view: LoginRouteAction)
    func pushMainView(view: MainRouteAction)
    func pushSettingView(view: SettingRouteAction)
}

class RootPresenter {
    private weak var view: RootViewProtocol?
    private let disposeBag = DisposeBag()

    fileprivate let routeStore: RouteStore
    fileprivate let dataStore: DataStore
    fileprivate let telemetryStore: TelemetryStore
    fileprivate let autoLockStore: AutoLockStore
    fileprivate let userDefaults: UserDefaults
    fileprivate let routeActionHandler: RouteActionHandler
    fileprivate let dataStoreActionHandler: DataStoreActionHandler
    fileprivate let telemetryActionHandler: TelemetryActionHandler
    fileprivate let biometryManager: BiometryManager

    init(view: RootViewProtocol,
         dispatcher: Dispatcher = Dispatcher.shared,
         routeStore: RouteStore = RouteStore.shared,
         dataStore: DataStore = DataStore.shared,
         telemetryStore: TelemetryStore = TelemetryStore.shared,
         autoLockStore: AutoLockStore = AutoLockStore.shared,
         userDefaults: UserDefaults = UserDefaults.standard,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         dataStoreActionHandler: DataStoreActionHandler = DataStoreActionHandler.shared,
         telemetryActionHandler: TelemetryActionHandler = TelemetryActionHandler.shared,
         biometryManager: BiometryManager = BiometryManager()
    ) {
        self.view = view
        self.routeStore = routeStore
        self.dataStore = dataStore
        self.telemetryStore = telemetryStore
        self.autoLockStore = autoLockStore
        self.userDefaults = userDefaults
        self.routeActionHandler = routeActionHandler
        self.dataStoreActionHandler = dataStoreActionHandler
        self.telemetryActionHandler = telemetryActionHandler
        self.biometryManager = biometryManager

        self.dataStore.storageState
            .subscribe(onNext: { storageState in
                    switch storageState {
                    case .Unprepared, .Locked:
                        self.routeActionHandler.invoke(LoginRouteAction.welcome)
                    case .Preparing, .Unlocked:
                        self.routeActionHandler.invoke(MainRouteAction.list)
                    default:
                        self.routeActionHandler.invoke(LoginRouteAction.welcome)
                    }
                })
                .disposed(by: self.disposeBag)

        self.dataStore.syncState
            .distinctUntilChanged()
            .subscribe(onNext: { syncState in
                if syncState == .NotSyncable {
                    self.routeActionHandler.invoke(LoginRouteAction.welcome)
                }
            })
            .disposed(by: self.disposeBag)

        self.startTelemetry()
        self.checkAutoLockTimer()
    }

    func onViewReady() {
        self.routeStore.onRoute
                .filterByType(class: LoginRouteAction.self)
                .asDriver(onErrorJustReturn: .welcome)
                .drive(showLogin)
                .disposed(by: disposeBag)

        self.routeStore.onRoute
                .filterByType(class: MainRouteAction.self)
                .asDriver(onErrorJustReturn: .list)
                .drive(showList)
                .disposed(by: disposeBag)

        self.routeStore.onRoute
                .filterByType(class: SettingRouteAction.self)
                .asDriver(onErrorJustReturn: .list)
                .drive(self.showSetting)
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
            case .learnMore:
                if !view.topViewIs(StaticURLWebView.self) {
                    view.pushLoginView(view: .learnMore)
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
            case .faqLink(let url):
                if !view.topViewIs(StaticURLWebView.self) {
                    view.pushMainView(view: .faqLink(urlString: url))
                }
            }
        }.asObserver()
    }()

    lazy private var showSetting: AnyObserver<SettingRouteAction> = { [unowned self] in
        return Binder(self) { target, settingAction in
            guard let view = target.view else {
                return
            }

            if !view.modalStackIs(SettingNavigationController.self) {
                view.startModalStack(SettingNavigationController.self)
            }

            switch settingAction {
            case .list:
                if !view.modalViewIs(SettingListView.self) {
                    view.pushSettingView(view: .list)
                }
            case .account:
                if !view.modalViewIs(AccountSettingView.self) {
                    view.pushSettingView(view: .account)
                }
            case .autoLock:
                if !view.modalViewIs(AutoLockSettingView.self) {
                    view.pushSettingView(view: .autoLock)
                }
            case .preferredBrowser:
                if !view.modalViewIs(PreferredBrowserSettingView.self) {
                    view.pushSettingView(view: .preferredBrowser)
                }
            case .faq:
                view.pushSettingView(view: .faq)
            case .provideFeedback:
                view.pushSettingView(view: .provideFeedback)
            }

        }.asObserver()
    }()
}

extension RootPresenter {
    fileprivate func startTelemetry() {
        Observable.combineLatest(self.telemetryStore.telemetryFilter, self.userDefaults.onRecordUsageData)
                .filter {
                    $0.1
                }
                .map {
                    $0.0
                }
                .bind(to: self.telemetryActionHandler.telemetryActionListener)
                .disposed(by: self.disposeBag)
    }

    fileprivate func checkAutoLockTimer() {
        guard self.biometryManager.deviceAuthenticationAvailable else {
            return
        }

        self.userDefaults.onAutoLockTime
                .take(1)
                .subscribe(onNext: { autoLockSetting in
                    switch autoLockSetting {
                    case .OnAppExit:
                        self.dataStoreActionHandler.invoke(.lock)
                    case .Never:
                        self.dataStoreActionHandler.invoke(.unlock)
                    default:
                        let date = NSDate(timeIntervalSince1970:
                        self.userDefaults.double(forKey: SettingKey.autoLockTimerDate.rawValue))

                        if date.timeIntervalSince1970 > 0 && date.timeIntervalSinceNow > 0 {
                            self.dataStoreActionHandler.invoke(.unlock)
                        } else {
                            self.dataStoreActionHandler.invoke(.lock)
                        }
                    }
                })
                .disposed(by: self.disposeBag)
    }
}

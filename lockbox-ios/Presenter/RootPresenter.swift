/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import UIKit
import FxAClient
import Logins

protocol RootViewProtocol: class {
    func topViewIs<T: UIViewController>(_ type: T.Type) -> Bool
    func modalViewIs<T: UIViewController>(_ type: T.Type) -> Bool
    func sidebarViewIs<T: UIViewController>(_ type: T.Type) -> Bool
    func detailViewIs<T: UIViewController>(_ type: T.Type) -> Bool
    func mainStackIs<T: UIViewController>(_ type: T.Type) -> Bool
    func modalStackIs<T: UIViewController>(_ type: T.Type) -> Bool
    var modalStackPresented: Bool { get }

    func startMainStack<T: UIViewController>(_ viewController: T)
    func startModalStack<T: UIViewController>(_ viewController: T)
    func dismissModals()

    func push(view: UIViewController)
    func pushSidebar(view: UIViewController)
    func pushDetail(view: UIViewController)
    func popView()
    func popToRoot()
}

struct SyncCredProfile {
    let syncCredentials: SyncUnlockInfo?
    let profile: Profile?
}

extension SyncCredProfile: Equatable {
    static func ==(lh: SyncCredProfile, rh: SyncCredProfile) -> Bool {
        return lh.profile == rh.profile &&
                lh.syncCredentials == rh.syncCredentials
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
    fileprivate let lifecycleStore: LifecycleStore
    fileprivate let telemetryActionHandler: TelemetryActionHandler
    fileprivate let biometryManager: BiometryManager
    fileprivate let sentryManager: Sentry
    fileprivate let adjustManager: AdjustManager
    fileprivate let viewFactory: ViewFactory
    fileprivate let sizeClassStore: SizeClassStore
    fileprivate let itemDetailStore: ItemDetailStore

    private var isDisplayingSidebar: Bool?

    var fxa: FirefoxAccount?

    init(view: RootViewProtocol,
         dispatcher: Dispatcher = .shared,
         routeStore: RouteStore = RouteStore.shared,
         dataStore: DataStore = DataStore.shared,
         telemetryStore: TelemetryStore = TelemetryStore.shared,
         accountStore: AccountStore = AccountStore.shared,
         userDefaultStore: UserDefaultStore = .shared,
         lifecycleStore: LifecycleStore = .shared,
         telemetryActionHandler: TelemetryActionHandler = TelemetryActionHandler(accountStore: AccountStore.shared),
         biometryManager: BiometryManager = BiometryManager(),
         sentryManager: Sentry = Sentry.shared,
         adjustManager: AdjustManager = AdjustManager.shared,
         viewFactory: ViewFactory = ViewFactory.shared,
         sizeClassStore: SizeClassStore = SizeClassStore.shared,
         itemDetailStore: ItemDetailStore = .shared
    ) {
        self.view = view
        self.dispatcher = dispatcher
        self.routeStore = routeStore
        self.dataStore = dataStore
        self.telemetryStore = telemetryStore
        self.accountStore = accountStore
        self.userDefaultStore = userDefaultStore
        self.lifecycleStore = lifecycleStore
        self.telemetryActionHandler = telemetryActionHandler
        self.biometryManager = biometryManager
        self.sentryManager = sentryManager
        self.adjustManager = adjustManager
        self.viewFactory = viewFactory
        self.sizeClassStore = sizeClassStore
        self.itemDetailStore = itemDetailStore

        self.accountStore.syncCredentials
                .distinctUntilChanged()
                .bind {
                    if let credentials = $0 {
                        self.dispatcher.dispatch(action: DataStoreAction.updateCredentials(syncInfo: credentials))
                    } else if $0 == nil {
                        self.dispatcher.dispatch(action: LoginRouteAction.welcome)
                        self.dispatcher.dispatch(action: DataStoreAction.reset)
                        self.dispatcher.dispatch(action: CredentialProviderAction.clear)
                        self.dispatcher.dispatch(action: AccountAction.clear)
                    }
                }
                .disposed(by: self.disposeBag)

        self.dataStore.storageState
            .map({ (storageState) -> [Action]? in
                switch storageState {
                case .Unprepared, .Locked:
                    return [LoginRouteAction.welcome]
                case .Unlocked:
                    return [MainRouteAction.list, CredentialProviderAction.refresh]
                default:
                    return nil
                }
            })
            .filterNil()
            .subscribe(onNext: { actions in
                actions.forEach { dispatcher.dispatch(action: $0) }
            })
            .disposed(by: self.disposeBag)

        Observable.combineLatest(self.dataStore.syncState, self.dataStore.storageState)
            .filter { $0.1 == LoginStoreState.Unprepared }
            .map { $0.0 }
            .distinctUntilChanged()
            .subscribe(onNext: { syncState in
                if syncState == .NotSyncable {
                    self.dispatcher.dispatch(action: LoginRouteAction.welcome)
                }
            })
            .disposed(by: self.disposeBag)

        self.lifecycleStore.lifecycleFilter
            .subscribe(onNext: { lifecycleAction in
                switch lifecycleAction {
                case .foreground:
                    self.hidePrivacyView()
                case .background:
                    self.showPrivacyView()
                default:
                    return
                }
            })
            .disposed(by: self.disposeBag)

        self.dispatcher.dispatch(action: OnboardingStatusAction(onboardingInProgress: false))
        self.startTelemetry()
        self.startAdjust()
        self.startSentry()
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

    func changeDisplay(traitCollection: UITraitCollection) {
        self.dispatcher.dispatch(action: SizeClassAction.changed(traitCollection: traitCollection))
    }

    lazy private var showLogin: AnyObserver<LoginRouteAction> = { [unowned self] in
        return Binder(self) { target, loginAction in
            guard let view = target.view else {
                return
            }

            if view.modalStackPresented {
                view.dismissModals()
            }

            if !view.mainStackIs(LoginNavigationController.self) {
                view.startMainStack(LoginNavigationController())
            }

            switch loginAction {
            case .welcome:
                if !view.topViewIs(WelcomeView.self) {
                    view.popToRoot()
                }
            case .fxa:
                if !view.topViewIs(FxAView.self) {
                    view.push(view: self.viewFactory.make(FxAView.self))
                }
            case .onboardingConfirmation:
                if !view.topViewIs(OnboardingConfirmationView.self) {
                    view.push(view: self.viewFactory.make(storyboardName: "OnboardingConfirmation", identifier: "onboardingconfirmation"))
                }
            case .autofillOnboarding:
                if !view.topViewIs(AutofillOnboardingView.self) {
                    view.push(view: self.viewFactory.make(storyboardName: "AutofillOnboarding", identifier: "autofillonboarding"))
                }
            case .autofillInstructions:
                if !view.topViewIs(AutofillInstructionsView.self) {
                    view.push(view: self.viewFactory.make(storyboardName: "SetupAutofill", identifier: "autofillinstructions"))
                }
            }
        }.asObserver()
    }()

    lazy private var showList: AnyObserver<MainRouteAction> = { [unowned self] in
        return Binder(self) { target, mainAction in
            guard let view = target.view else {
                return
            }

            if view.modalStackPresented {
                view.dismissModals()
            }

            if !view.mainStackIs(SplitView.self) {
                view.startMainStack(SplitView(delegate: self))
            }

            switch mainAction {
            case .list:
                if !view.topViewIs(ItemListView.self) {
                    view.popToRoot()
                }
            case .detail(let id):
                if !view.topViewIs(ItemDetailView.self) {
                    let detailView: ItemDetailView = self.viewFactory.make(storyboardName: "ItemDetail", identifier: "itemdetailview")

                    self.sizeClassStore.shouldDisplaySidebar
                        .take(1)
                        .subscribe(onNext: { enableSidebar in
                            if enableSidebar {
                                view.pushDetail(view: detailView)
                            } else {
                                view.push(view: detailView)
                            }
                        })
                        .disposed(by: self.disposeBag)
                }
            }
        }.asObserver()
    }()

    lazy private var showSetting: AnyObserver<SettingRouteAction> = { [unowned self] in
        return Binder(self) { target, settingAction in
            guard let view = target.view else {
                return
            }

            if view.modalStackPresented {
                view.dismissModals()
            }

            if !view.mainStackIs(SettingNavigationController.self) {
                view.startMainStack(SettingNavigationController())
            }

            switch settingAction {
            case .list:
                if !view.topViewIs(SettingListView.self) {
                    view.popToRoot()
                }
            case .account:
                if !view.topViewIs(AccountSettingView.self) {
                    view.push(view: self.viewFactory.make(storyboardName: "AccountSetting", identifier: "accountsetting"))
                }
            case .autoLock:
                if !view.topViewIs(AutoLockSettingView.self) {
                    view.push(view: self.viewFactory.make(AutoLockSettingView.self))
                }
            case .preferredBrowser:
                if !view.topViewIs(PreferredBrowserSettingView.self) {
                    view.push(view: self.viewFactory.make(PreferredBrowserSettingView.self))
                }
            case .autofillInstructions:
                if !view.modalStackIs(AutofillInstructionsNavigationController.self) {
                    view.startModalStack(AutofillInstructionsNavigationController())
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
            self.adjustManager.setEnabled(enabled)
        }).disposed(by: self.disposeBag)
    }

    fileprivate func startSentry() {
        self.userDefaultStore.recordUsageData
            .take(1)
            .subscribe(onNext: { enabled in
                self.sentryManager.setup(sendUsageData: enabled)
        }).disposed(by: self.disposeBag)
    }

    private func hidePrivacyView() {
        guard let view = self.view else { return }

        if view.modalStackIs(PrivacyView.self) {
            view.dismissModals()
        }
    }

    private func showPrivacyView() {
        let vc = self.viewFactory.make(storyboardName: "PrivacyScreen", identifier: "privacyview")
        self.view?.startModalStack(vc)
    }
}

extension RootPresenter: UISplitViewControllerDelegate {
    func primaryViewController(forCollapsing splitViewController: UISplitViewController) -> UIViewController? {
        let newNavController = MainNavigationController(storyboardName: "ItemList", identifier: "itemlist")
        if itemDetailStore.itemDetailHasId {
            let detailView: ItemDetailView = self.viewFactory.make(storyboardName: "ItemDetail", identifier: "itemdetailview")
            newNavController.pushViewController(detailView, animated: false)
        }

        return newNavController
    }

    func primaryViewController(forExpanding splitViewController: UISplitViewController) -> UIViewController? {
        if let splitView = splitViewController as? SplitView {
            return splitView.sidebarView
        }

        return nil
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }

    func splitViewController(_ splitViewController: UISplitViewController, separateSecondaryFrom primaryViewController: UIViewController) -> UIViewController? {

        if let navController = primaryViewController as? UINavigationController {
            if navController.popViewController(animated: false) as? ItemDetailView != nil {
                let newDetailView: ItemDetailView = self.viewFactory.make(storyboardName: "ItemDetail", identifier: "itemdetailview")
                return MainNavigationController(rootViewController: newDetailView)
            }
        }

        return nil
    }

    func splitViewController(_ splitViewController: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool {
        return true
    }
}

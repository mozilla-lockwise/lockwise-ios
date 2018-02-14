/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

protocol RootViewProtocol: class {
    func topViewIs<T>(_ class: T.Type) -> Bool

    var loginStackDisplayed: Bool { get }
    func startLoginStack()
    func pushLoginView(view: LoginRouteAction)

    var mainStackDisplayed: Bool { get }
    func startMainStack()
    func pushMainView(view: MainRouteAction)
}

struct KeyInit {
    let scopedKey: String?
    let initialized: Bool
}

struct InfoOpen {
    let profileInfo: ProfileInfo?
    let opened: Bool
}

struct KeyLock {
    let scopedKey: String?
    let locked: Bool
}

class RootPresenter {
    private weak var view: RootViewProtocol?
    private let disposeBag = DisposeBag()

    fileprivate let routeStore: RouteStore
    fileprivate let userInfoStore: UserInfoStore
    fileprivate let dataStore: DataStore
    fileprivate let routeActionHandler: RouteActionHandler
    fileprivate let dataStoreActionHandler: DataStoreActionHandler

    init(view: RootViewProtocol,
         routeStore: RouteStore = RouteStore.shared,
         userInfoStore: UserInfoStore = UserInfoStore.shared,
         dataStore: DataStore = DataStore.shared,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         dataStoreActionHandler: DataStoreActionHandler = DataStoreActionHandler.shared
    ) {
        self.view = view
        self.routeStore = routeStore
        self.userInfoStore = userInfoStore
        self.dataStore = dataStore
        self.routeActionHandler = routeActionHandler
        self.dataStoreActionHandler = dataStoreActionHandler

        // request init & lock status update on app launch
        self.dataStoreActionHandler.updateInitialized()
        self.dataStoreActionHandler.updateLocked()

        Observable.combineLatest(self.userInfoStore.profileInfo, self.dataStore.onOpened)
                .map { (latest: (ProfileInfo?, Bool)) -> InfoOpen in
                    return InfoOpen(profileInfo: latest.0, opened: latest.1)
                }
                .subscribe(onNext: { (latest: InfoOpen) in
                    guard let uid = latest.profileInfo?.uid else {
                        self.routeActionHandler.invoke(LoginRouteAction.welcome)
                        return
                    }

                    if !latest.opened {
                        self.dataStoreActionHandler.open(uid: uid)
                    }
                }).disposed(by: self.disposeBag)

        Observable.combineLatest(self.userInfoStore.scopedKey, self.dataStore.onInitialized)
                .map { (latest: (String?, Bool)) -> KeyInit in
                    return KeyInit(scopedKey: latest.0, initialized: latest.1)
                }
                .filter { latest in
                    return (latest.scopedKey != nil)
                }
                .subscribe(onNext: { (latest: KeyInit) in
                    guard let scopedKey = latest.scopedKey else {
                        return
                    }

                    if !latest.initialized {
                        self.dataStoreActionHandler.initialize(scopedKey: scopedKey)
                        return
                    } else {
                        self.dataStoreActionHandler.populateTestData()
                    }

                    self.routeActionHandler.invoke(MainRouteAction.list)
                })
                .disposed(by: self.disposeBag)

        self.unlockBlindly()
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
    }

    lazy private var showLogin: AnyObserver<LoginRouteAction> = { [unowned self] in
        return Binder(self) { target, loginAction in
            guard let view = target.view else {
                return
            }

            if !view.loginStackDisplayed {
                view.startLoginStack()
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
            }
        }.asObserver()
    }()

    lazy private var showList: AnyObserver<MainRouteAction> = { [unowned self] in
        return Binder(self) { target, mainAction in
            guard let view = target.view else {
                return
            }

            if !view.mainStackDisplayed {
                view.startMainStack()
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
}

extension RootPresenter {
    private func unlockBlindly() {
        Observable.combineLatest(self.dataStore.onInitialized, self.userInfoStore.scopedKey, self.dataStore.onLocked)
                .filter { (latest: (Bool, String?, Bool)) -> Bool in
                    return latest.0
                }
                .map { (latest: (Bool, String?, Bool)) -> KeyLock in
                    return KeyLock(scopedKey: latest.1, locked: latest.2)
                }
                .subscribe(onNext: { (latest: KeyLock) in
                    guard let scopedKey = latest.scopedKey else {
                        return
                    }

                    if latest.locked {
                        self.dataStoreActionHandler.unlock(scopedKey: scopedKey)
                    } else {
                        self.dataStoreActionHandler.list()
                    }
                })
                .disposed(by: self.disposeBag)
    }
}

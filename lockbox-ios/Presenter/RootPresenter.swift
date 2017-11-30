/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

protocol RootViewProtocol: class {
    func topViewIs<T>(_ class: T.Type) -> Bool

    var loginStackDisplayed:Bool { get }
    func startLoginStack()
    func pushLoginView(view: LoginRouteAction)

    var mainStackDisplayed:Bool { get }
    func startMainStack()
    func pushMainView(view: MainRouteAction)
}

struct InfoKeyInit {
    let profileInfo:ProfileInfo?
    let scopedKey:String?
    let initialized:Bool
}

struct KeyLock {
    let scopedKey:String?
    let locked:Bool
}

class RootPresenter {
    private weak var view: RootViewProtocol?
    private let disposeBag = DisposeBag()

    fileprivate let routeStore:RouteStore
    fileprivate let userInfoStore:UserInfoStore
    fileprivate let dataStore:DataStore
    fileprivate let routeActionHandler:RouteActionHandler
    fileprivate let dataStoreActionHandler:DataStoreActionHandler

    init(view:RootViewProtocol,
         routeStore:RouteStore = RouteStore.shared,
         userInfoStore:UserInfoStore = UserInfoStore.shared,
         dataStore:DataStore = DataStore.shared,
         routeActionHandler:RouteActionHandler = RouteActionHandler.shared,
         dataStoreActionHandler:DataStoreActionHandler = DataStoreActionHandler.shared
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

        // initialize if not initialized
        Observable.combineLatest(self.userInfoStore.profileInfo, self.userInfoStore.scopedKey, self.dataStore.onInitialized)
                .map { (element: (ProfileInfo?, String?, Bool)) -> InfoKeyInit in
                    return InfoKeyInit(profileInfo: element.0, scopedKey: element.1, initialized: element.2)
                 }
                .filter { (latest: InfoKeyInit) in
                    return (latest.profileInfo != nil) == (latest.scopedKey != nil)
                }
                .subscribe(onNext: { (latest: InfoKeyInit) in
                    guard let info = latest.profileInfo,
                          let scopedKey = latest.scopedKey else {
                        self.routeActionHandler.invoke(LoginRouteAction.welcome)
                        return
                    }

                    if !latest.initialized {
                        self.dataStoreActionHandler.initialize(scopedKey: scopedKey, uid: info.uid)
                    }
                })
                .disposed(by: self.disposeBag)

        // blindly unlock for now
        Observable.combineLatest(self.userInfoStore.scopedKey, self.dataStore.onLocked)
                .map { (element: (String?, Bool)) -> KeyLock in
                    return KeyLock(scopedKey: element.0, locked: element.1)
                 }
                .filter { (latest: KeyLock) in
                    return latest.scopedKey != nil && latest.locked
                }
                .subscribe(onNext: { (latest: KeyLock) in
                    guard let scopedKey = latest.scopedKey else { return }

                    if latest.locked {
                        self.dataStoreActionHandler.unlock(scopedKey: scopedKey)
                    }
                })
                .disposed(by: self.disposeBag)
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

    lazy fileprivate var showLogin:AnyObserver<LoginRouteAction> = { [unowned self] in
        return Binder(self) { target, loginAction in
            guard let view = self.view else { return }

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

    lazy fileprivate var showList:AnyObserver<MainRouteAction> = { [unowned self] in
        return Binder(self) { target, mainAction in
            guard let view = self.view else { return }

            if !view.mainStackDisplayed {
                view.startMainStack()
            }

            switch mainAction {
                case .list:
                    if !view.topViewIs(ItemListView.self) {
                        view.pushMainView(view: .list)
                    }
                case .detail(_): break
            }
        }.asObserver()
    }()
}

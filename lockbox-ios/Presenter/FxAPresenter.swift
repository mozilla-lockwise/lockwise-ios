/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import RxSwift
import RxCocoa

protocol FxAViewProtocol: class, ErrorView {
    func loadRequest(_ urlRequest: URLRequest)
}

struct DisplayLock {
    let action: FxADisplayAction
    let locked: Bool
}

class FxAPresenter {
    private weak var view: FxAViewProtocol?
    fileprivate let fxAActionHandler: FxAActionHandler
    fileprivate let settingActionHandler: SettingActionHandler
    fileprivate let routeActionHandler: RouteActionHandler
    fileprivate let fxaStore: FxAStore
    fileprivate let userDefaults: UserDefaults

    private var disposeBag = DisposeBag()

    public var onCancel: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(LoginRouteAction.welcome)
        }.asObserver()
    }

    init(view: FxAViewProtocol,
         fxAActionHandler: FxAActionHandler = FxAActionHandler.shared,
         settingActionHandler: SettingActionHandler = SettingActionHandler.shared,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         fxaStore: FxAStore = FxAStore.shared,
         userDefaults: UserDefaults = UserDefaults.standard) {
        self.view = view
        self.fxAActionHandler = fxAActionHandler
        self.settingActionHandler = settingActionHandler
        self.routeActionHandler = routeActionHandler
        self.fxaStore = fxaStore
        self.userDefaults = userDefaults
    }

    func onViewReady() {
        let lockedDriver = self.userDefaults.onLock
                .asDriver(onErrorJustReturn: false)

        Driver.combineLatest(self.fxaStore.fxADisplay, lockedDriver)
                .map { latest -> DisplayLock in
                    return DisplayLock(action: latest.0, locked: latest.1)
                }
                .drive(onNext: { latest in
                    switch latest.action {
                    case .loadInitialURL(let url):
                        self.view?.loadRequest(URLRequest(url: url))
                    case .finishedFetchingUserInformation:
                        if latest.locked {
                            self.settingActionHandler.invoke(SettingAction.lock(locked: false))
                        }

                        self.routeActionHandler.invoke(MainRouteAction.list)
                    default:
                        break
                    }
                })
                .disposed(by: self.disposeBag)

        self.fxAActionHandler.initiateFxAAuthentication()
    }

    func webViewRequest(decidePolicyFor navigationAction: WKNavigationAction,
                        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let navigationURL = navigationAction.request.url {
            if "\(navigationURL.scheme!)://\(navigationURL.host!)\(navigationURL.path)" == Constant.app.redirectURI,
               let components = URLComponents(url: navigationURL, resolvingAgainstBaseURL: true) {
                self.fxAActionHandler.matchingRedirectURLReceived(components: components)
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// swiftlint:disable

import Foundation
import WebKit
import RxSwift
import RxCocoa
import SwiftyJSON

protocol FxAViewProtocol: class {
    func loadRequest(_ urlRequest: URLRequest)
}

struct LockedSyncState {
    let locked: Bool
    let state: SyncState
}

class FxAPresenter {
    private weak var view: FxAViewProtocol?
    fileprivate let accountActionHandler: AccountActionHandler
    fileprivate let routeActionHandler: RouteActionHandler
    fileprivate let accountStore: AccountStore

    private var disposeBag = DisposeBag()

    public var onClose: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(LoginRouteAction.welcome)
        }.asObserver()
    }

    init(view: FxAViewProtocol,
         accountActionHandler: AccountActionHandler = AccountActionHandler.shared,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         accountStore: AccountStore = AccountStore.shared
    ) {
        self.view = view
        self.accountActionHandler = accountActionHandler
        self.routeActionHandler = routeActionHandler
        self.accountStore = accountStore
    }

    func onViewReady() {
        self.accountStore.loginURL
                .bind { url in
                    self.view?.loadRequest(URLRequest(url: url))
                }
                .disposed(by: self.disposeBag)
    }
}

// Extensions and enums to support logging in via remote commmand.
extension FxAPresenter {
    func matchingRedirectURLReceived(_ navigationURL: URL) {
        self.accountActionHandler.invoke(.oauthRedirect(url: navigationURL))
    }
}

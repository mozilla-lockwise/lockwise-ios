/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
    fileprivate let dispatcher: Dispatcher
    fileprivate let accountStore: AccountStore

    private var disposeBag = DisposeBag()

    public var onClose: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: LoginRouteAction.welcome)
        }.asObserver()
    }

    init(view: FxAViewProtocol,
         dispatcher: Dispatcher = .shared,
         accountStore: AccountStore = AccountStore.shared
    ) {
        self.view = view
        self.dispatcher = dispatcher
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
        self.dispatcher.dispatch(action: OnboardingStatusAction(onboardingInProgress: true))
        self.dispatcher.dispatch(action: LoginRouteAction.onboardingConfirmation)
        self.dispatcher.dispatch(action: AccountAction.oauthRedirect(url: navigationURL))
    }
}

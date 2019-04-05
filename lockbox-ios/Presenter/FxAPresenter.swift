/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import RxSwift
import RxCocoa

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
    private let adjustManager: AdjustManager

    fileprivate var _credentialProviderStore: Any?

    @available (iOS 12, *)
    private var credentialProviderStore: CredentialProviderStore {
        if let store = _credentialProviderStore as? CredentialProviderStore {
            return store
        }

        return CredentialProviderStore.shared
    }

    private let _nextRouteSubject = ReplaySubject<LoginRouteAction>.create(bufferSize: 1)

    var nextRoute: Observable<LoginRouteAction> {
        return self._nextRouteSubject.asObservable()
    }

    private var disposeBag = DisposeBag()

    public var onClose: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: LoginRouteAction.welcome)
        }.asObserver()
    }

    init(view: FxAViewProtocol,
         dispatcher: Dispatcher = .shared,
         accountStore: AccountStore = AccountStore.shared,
         adjustManager: AdjustManager = AdjustManager.shared
    ) {
        self.view = view
        self.dispatcher = dispatcher
        self.accountStore = accountStore
        self.adjustManager = adjustManager
    }

    @available(iOS 12, *)
    init(view: FxAViewProtocol,
         dispatcher: Dispatcher = .shared,
         accountStore: AccountStore = AccountStore.shared,
         credentialProviderStore: CredentialProviderStore = CredentialProviderStore.shared,
         adjustManager: AdjustManager = AdjustManager.shared
        ) {
        self.view = view
        self.dispatcher = dispatcher
        self.accountStore = accountStore
        self._credentialProviderStore = credentialProviderStore
        self.adjustManager = adjustManager
    }

    func onViewReady() {
        self.accountStore.loginURL
                .bind { url in
                    self.view?.loadRequest(URLRequest(url: url))
                }
                .disposed(by: self.disposeBag)

        if #available(iOS 12.0, *) {
            self.credentialProviderStore.state
                .map({ state in
                    return state == .NotAllowed ? LoginRouteAction.autofillOnboarding : LoginRouteAction.onboardingConfirmation
                }).subscribe(onNext: { route in
                    self._nextRouteSubject.onNext(route)
                }).disposed(by: self.disposeBag)
        } else {
            _nextRouteSubject.onNext(.onboardingConfirmation)
        }
    }
}

// Extensions and enums to support logging in via remote commmand.
extension FxAPresenter {
    func matchingRedirectURLReceived(_ navigationURL: URL) {
        self.dispatcher.dispatch(action: OnboardingStatusAction(onboardingInProgress: true))

        self.nextRoute
            .take(1)
            .subscribe(onNext: { action in
                self.dispatcher.dispatch(action: action)
            }).disposed(by: self.disposeBag)
        self.dispatcher.dispatch(action: AccountAction.oauthRedirect(url: navigationURL))
        self.adjustManager.trackEvent(.FxaComplete)
    }
}

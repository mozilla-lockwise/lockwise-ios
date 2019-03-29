/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AuthenticationServices
import RxSwift
import RxCocoa
import Logins

enum CredentialProviderStoreState {
    case NotAllowed, Populating, Populated, Allowed
}

@available(iOS 12, *)
class CredentialProviderStore {
    public static let shared = CredentialProviderStore()

    private let dispatcher: Dispatcher
    private let dataStore: DataStore
    private let credentialStore: CredentialIdentityStoreProtocol
    private let accountStore: BaseAccountStore
    private let disposeBag = DisposeBag()

    private let _stateSubject = ReplaySubject<CredentialProviderStoreState>.create(bufferSize: 1)

    private let _authenticationDisplay = ReplaySubject<Bool>.create(bufferSize: 1)

    var state: Observable<CredentialProviderStoreState> {
        return self._stateSubject.asObservable()
    }

    var displayAuthentication: Observable<Bool> {
        return self._authenticationDisplay.asObservable()
    }

    init(dispatcher: Dispatcher = .shared,
         dataStore: DataStore = .shared,
         credentialStore: CredentialIdentityStoreProtocol = ASCredentialIdentityStore.shared,
         accountStore: BaseAccountStore = AccountStore.shared) {
        self.dispatcher = dispatcher
        self.dataStore = dataStore
        self.credentialStore = credentialStore
        self.accountStore = accountStore

        self.dispatcher.register
                .filterByType(class: CredentialProviderAction.self)
                .subscribe(onNext: { [weak self] action in
                    switch action {
                    case .refresh:
                        self?.checkStateAndRefresh()
                    case .authenticationRequested:
                        self?._authenticationDisplay.onNext(true)
                    case .authenticated:
                        self?._authenticationDisplay.onNext(false)
                    case.clear:
                        self?.clear()
                    }
                })
                .disposed(by: self.disposeBag)

        self.credentialStore.getState { [weak self] state in
            self?._stateSubject.onNext(state.isEnabled ? .Allowed : .NotAllowed)
        }
    }
}

@available(iOS 12, *)
extension CredentialProviderStore {
    private func clear() {
        self.clearCredentialStore()
                .subscribe()
                .disposed(by: self.disposeBag)
    }
    
    private func checkStateAndRefresh() {
        self.credentialStore.getState { [weak self] state in
            if state.isEnabled {
                self?.refresh()
            } else {
                self?._stateSubject.onNext(.NotAllowed)
            }
        }
    }

    private func refresh() {
        Observable.combineLatest(self.dataStore.list, self.accountStore.syncCredentials)
            .filter { !$0.0.isEmpty && $0.1 != nil }
            .map { $0.0 }
            .bind { _ in
                self._stateSubject.onNext(.Populated)
            }
            .disposed(by: self.disposeBag)

        self._stateSubject.onNext(.Populating)

        let loginObservable = self.dataStore.list.filterEmpty()

        loginObservable.flatMap { logins -> Observable<(Void, [LoginRecord])> in
                    self._stateSubject.onNext(.Populating)
                    let clearObservable = self.clearCredentialStore()
                        .asObservable()
                    let justLoginObservable = Observable.just(logins)

                    return Observable.combineLatest(clearObservable, justLoginObservable)
                }
                .map { $0.1 }
                .map { logins -> [ASPasswordCredentialIdentity] in
                    return logins.map { login -> ASPasswordCredentialIdentity in
                        login.passwordCredentialIdentity
                    }
                }
                .flatMap { credentialIdentities -> Single<Void> in
                    return self.populateCredentialStore(identities: credentialIdentities)
                }
                .subscribe { _ in
                    self._stateSubject.onNext(.Populated)
                }
                .disposed(by: self.disposeBag)
    }

    private func populateCredentialStore(identities: [ASPasswordCredentialIdentity]) -> Single<Void> {
        return Single.create { [weak self] observer in
            self?.credentialStore.saveCredentialIdentities(identities) { (success, error) in
                if success {
                    observer(.success(()))
                } else if let err = error {
                    observer(.error(err))
                }
            }

            return Disposables.create()
        }
    }

    private func clearCredentialStore() -> Single<Void> {
        return Single.create { [weak self] observer in
            self?.credentialStore.removeAllCredentialIdentities { (success, error) in
                if success {
                    observer(.success(()))
                } else if let err = error {
                    observer(.error(err))
                }
            }

            return Disposables.create()
        }
    }
}

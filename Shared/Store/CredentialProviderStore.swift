/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AuthenticationServices
import RxSwift
import RxCocoa
import Storage

enum CredentialProviderStoreState {
    case NotAllowed, Populating, Populated
}

@available(iOS 12, *)
class CredentialProviderStore {
    public static let shared = CredentialProviderStore()

    private let dispatcher: Dispatcher
    private let dataStore: DataStore
    private let credentialStore: CredentialIdentityStoreProtocol
    private let disposeBag = DisposeBag()

    private let _stateSubject = ReplaySubject<CredentialProviderStoreState>.create(bufferSize: 1)

    var state: Observable<CredentialProviderStoreState> {
        return self._stateSubject.asObservable()
    }

    init(dispatcher: Dispatcher = .shared,
         dataStore: DataStore = .shared,
         credentialStore: CredentialIdentityStoreProtocol = ASCredentialIdentityStore.shared) {
        self.dispatcher = dispatcher
        self.dataStore = dataStore
        self.credentialStore = credentialStore

        self.dispatcher.register
                .filterByType(class: CredentialProviderAction.self)
                .subscribe(onNext: { [weak self] action in
                    switch action {
                    case .refresh:
                        self?.checkStateAndRefresh()
                    }
                })
                .disposed(by: self.disposeBag)

        self.credentialStore.getState { [weak self] state in
            if !state.isEnabled {
                self?._stateSubject.onNext(.NotAllowed)
            }
        }
    }
}

@available(iOS 12, *)
extension CredentialProviderStore {
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
        self._stateSubject.onNext(.Populating)

        self.clearCredentialStore()
                .asObservable()
                .flatMap { _ -> Observable<[Login]> in
                    return self.dataStore.list
                }
                .map { logins -> [ASPasswordCredentialIdentity] in
                    return logins.map { login -> ASPasswordCredentialIdentity in
                        self.credentialIdentityFromLogin(login)
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
    
    private func credentialIdentityFromLogin(_ login: Login) -> ASPasswordCredentialIdentity {
        let serviceIdentifier = ASCredentialServiceIdentifier(identifier: login.hostname, type: .URL)
        let username = login.username ?? "" // todo: what should the default value be?
        
        return ASPasswordCredentialIdentity(serviceIdentifier: serviceIdentifier, user: username, recordIdentifier: login.guid)
    }
}

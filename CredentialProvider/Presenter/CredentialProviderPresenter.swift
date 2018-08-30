/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AuthenticationServices
import RxSwift
import RxCocoa

@available(iOS 12, *)
protocol CredentialProviderViewProtocol: class, AlertControllerView {
    var extensionContext: ASCredentialProviderExtensionContext { get }

    func displayWelcome()
}

@available(iOS 12, *)
class CredentialProviderPresenter {
    weak var view: CredentialProviderViewProtocol?

    private let dispatcher: Dispatcher
    private let accountStore: AccountStore
    private let credentialProviderStore: CredentialProviderStore
    private let autoLockStore: AutoLockStore
    private let dataStore: DataStore
    private let disposeBag = DisposeBag()

    private var dismissObserver: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.cancelWith(.userCanceled)
        }.asObserver()
    }

    init(view: CredentialProviderViewProtocol,
         dispatcher: Dispatcher = .shared,
         accountStore: AccountStore = .shared,
         credentialProviderStore: CredentialProviderStore = .shared,
         autoLockStore: AutoLockStore = .shared,
         dataStore: DataStore = .shared) {
        self.view = view
        self.dispatcher = dispatcher
        self.accountStore = accountStore
        self.credentialProviderStore = credentialProviderStore
        self.autoLockStore = autoLockStore
        self.dataStore = dataStore

        Observable.combineLatest(self.accountStore.oauthInfo, self.accountStore.profile)
            .bind { (oauthInfo, profile) in
                if let oauthInfo = oauthInfo,
                    let profile = profile {
                    self.dispatcher.dispatch(action: DataStoreAction.updateCredentials(oauthInfo: oauthInfo, fxaProfile: profile))
                }
            }
            .disposed(by: self.disposeBag)

        self.dispatcher.register
            .filterByType(class: CredentialStatusAction.self)
            .subscribe(onNext: { action in
                switch action {
                case .extensionConfigured:
                    self.view?.extensionContext.completeExtensionConfigurationRequest()
                case .loginSelected(let login):
                    self.view?.extensionContext.completeRequest(withSelectedCredential: login.passwordCredential) { _ in
                        self.dispatcher.dispatch(action: DataStoreAction.touch(id: login.guid))
                    }
                default:
                    break
                }
            })
            .disposed(by: self.disposeBag)

        self.dispatcher.dispatch(action: LifecycleAction.foreground)
    }

    func extensionConfigurationRequested() {
        self.dispatcher.dispatch(action: DataStoreAction.unlock)
        self.dispatcher.dispatch(action: CredentialProviderAction.refresh)
        self.view?.displayWelcome()
    }

    func credentialProvisionRequested(for credentialIdentity: ASPasswordCredentialIdentity) {
        self.dataStore.locked
            .bind { locked in
                if locked {
                    self.cancelWith(.userInteractionRequired)
                } else {
                    self.provideCredential(for: credentialIdentity)
                }
            }
            .disposed(by: self.disposeBag)
    }

    func credentialProvisionInterface(for credentialIdentity: ASPasswordCredentialIdentity) {
        self.dataStore.locked
            .bind { locked in
                if locked {
                    self.dispatcher.dispatch(action: CredentialProviderAction.authenticationRequested)
                    self.view?.displayWelcome()
                } else {
                    self.provideCredential(for: credentialIdentity)
                }
            }
            .disposed(by: self.disposeBag)
    }

    func credentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        self.dataStore.locked
            .bind { locked in
                if locked {
                    self.dispatcher.dispatch(action: CredentialProviderAction.authenticationRequested)
                    self.view?.displayWelcome()
                } else {
                    self.view?.displayAlertController(buttons: [
                            AlertActionButtonConfiguration(title: "OK", tapObserver: self.dismissObserver, style: .default)
                        ],
                                                      title: "Credential list not available yet",
                                                      message: "Please check back later",
                                                      style: .alert)
                }
            }
            .disposed(by: self.disposeBag)
    }
}

@available(iOS 12, *)
extension CredentialProviderPresenter {
    private func provideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard let guid = credentialIdentity.recordIdentifier else {
            self.cancelWith(.credentialIdentityNotFound)
            return
        }

        self.dataStore.get(guid)
                .bind { login in
                    guard let login = login else {
                        self.cancelWith(.credentialIdentityNotFound)
                        return
                    }

                    self.dispatcher.dispatch(action: CredentialStatusAction.loginSelected(login: login))
                }
                .disposed(by: self.disposeBag)
    }

    private func cancelWith(_ errorCode: ASExtensionError.Code) {
        let error = NSError(domain: ASExtensionErrorDomain,
                            code: errorCode.rawValue,
                            userInfo: nil)

        self.view?.extensionContext.cancelRequest(withError: error)
    }
}

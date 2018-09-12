/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import AuthenticationServices
import Foundation
import RxSwift
import RxCocoa
import Storage

@available(iOS 12, *)
protocol CredentialProviderViewProtocol: class, AlertControllerView {
    var extensionContext: ASCredentialProviderExtensionContext { get }

    func displayWelcome()
    func displayItemList()
}

@available(iOS 12, *)
class CredentialProviderPresenter {
    weak var view: CredentialProviderViewProtocol?

    private let dispatcher: Dispatcher
    private let accountStore: AccountStore
    private let telemetryStore: TelemetryStore
    private let userDefaultStore: UserDefaultStore
    private let dataStore: DataStore
    private let telemetryActionHandler: TelemetryActionHandler
    private let credentialProviderStore: CredentialProviderStore
    private let autoLockStore: AutoLockStore
    private let disposeBag = DisposeBag()

    private var dismissObserver: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.cancelWith(.userCanceled)
        }.asObserver()
    }

    init(view: CredentialProviderViewProtocol,
         dispatcher: Dispatcher = .shared,
         accountStore: AccountStore = .shared,
         telemetryStore: TelemetryStore = .shared,
         userDefaultStore: UserDefaultStore = .shared,
         dataStore: DataStore = .shared,
         telemetryActionHandler: TelemetryActionHandler = .shared,
         credentialProviderStore: CredentialProviderStore = .shared,
         autoLockStore: AutoLockStore = .shared) {
        self.view = view
        self.dispatcher = dispatcher
        self.accountStore = accountStore
        self.telemetryStore = telemetryStore
        self.userDefaultStore = userDefaultStore
        self.dataStore = dataStore
        self.telemetryActionHandler = telemetryActionHandler
        self.credentialProviderStore = credentialProviderStore
        self.autoLockStore = autoLockStore

        Observable.combineLatest(self.accountStore.oauthInfo, self.accountStore.profile)
            .bind { [weak self] (oauthInfo, profile) in
                if let oauthInfo = oauthInfo,
                    let profile = profile {
                    self?.dispatcher.dispatch(action: DataStoreAction.updateCredentials(oauthInfo: oauthInfo, fxaProfile: profile))
                }
            }
            .disposed(by: self.disposeBag)

        self.dispatcher.register
            .filterByType(class: CredentialStatusAction.self)
            .subscribe(onNext: { [weak self] action in
                switch action {
                case .extensionConfigured:
                    self?.view?.extensionContext.completeExtensionConfigurationRequest()
                case .loginSelected(let login, let relock):
                    self?.view?.extensionContext.completeRequest(withSelectedCredential: login.passwordCredential) { _ in
                        self?.dispatcher.dispatch(action: DataStoreAction.touch(id: login.guid))

                        if relock {
                            self?.dispatcher.dispatch(action: DataStoreAction.lock)
                        }
                    }
                case .userCanceled:
                    self?.cancelWith(.userCanceled)
                }
            })
            .disposed(by: self.disposeBag)

        self.dispatcher.dispatch(action: LifecycleAction.foreground)
        self.dispatcher.dispatch(action: DataStoreAction.unlock)
        self.startTelemetry()
    }

    func extensionConfigurationRequested() {
        self.dispatcher.dispatch(action: LifecycleAction.foreground)

        self.dataStore.locked
                .bind { [weak self] locked in
                    if locked {
                        self?.dispatcher.dispatch(action: CredentialProviderAction.authenticationRequested)
                    } else {
                        self?.dispatcher.dispatch(action: CredentialProviderAction.refresh)
                    }
                }
                .disposed(by: self.disposeBag)

        self.view?.displayWelcome()
    }

    func credentialProvisionRequested(for credentialIdentity: ASPasswordCredentialIdentity) {
        self.dispatcher.dispatch(action: LifecycleAction.foreground)

        self.dataStore.locked
                .take(1)
                .bind { [weak self] locked in
                    if locked {
                        self?.dispatcher.dispatch(action: DataStoreAction.unlock)
                    }

                    self?.provideCredential(for: credentialIdentity, relock: locked)
                }
                .disposed(by: self.disposeBag)
    }

    func credentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        self.dispatcher.dispatch(action: LifecycleAction.foreground)

        self.dataStore.locked
                .bind { [weak self] locked in
                    if locked {
                        self?.dispatcher.dispatch(action: CredentialProviderAction.authenticationRequested)
                        self?.view?.displayWelcome()
                    } else {
                        self?.view?.displayItemList()
//                        guard let dismissObserver = self?.dismissObserver else { return }
//                        self?.view?.displayAlertController(buttons: [
//                                AlertActionButtonConfiguration(title: "OK", tapObserver: dismissObserver, style: .default)
//                            ],
//                                                          title: "Credential list not available yet",
//                                                          message: "Please check back later",
//                                                          style: .alert)
                    }
                }
                .disposed(by: self.disposeBag)
    }
}

@available(iOS 12, *)
extension CredentialProviderPresenter {
    private func provideCredential(for credentialIdentity: ASPasswordCredentialIdentity, relock: Bool) {
        guard let guid = credentialIdentity.recordIdentifier else {
            self.cancelWith(.credentialIdentityNotFound)
            return
        }

        self.dataStore.get(guid)
                .bind { [weak self] login in
                    guard let login = login else {
                        self?.cancelWith(.credentialIdentityNotFound)
                        return
                    }

                    self?.dispatcher.dispatch(action: CredentialStatusAction.loginSelected(login: login, relock: relock))
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

@available(iOS 12, *)
extension CredentialProviderPresenter {
    fileprivate func startTelemetry() {
        Observable.combineLatest(self.telemetryStore.telemetryFilter, self.userDefaultStore.recordUsageData)
            .filter { $0.1 }
            .map { $0.0 }
            .bind(to: self.telemetryActionHandler.telemetryActionListener)
            .disposed(by: self.disposeBag)
    }
}

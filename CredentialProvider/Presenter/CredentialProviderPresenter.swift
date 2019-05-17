/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import AuthenticationServices
import Foundation
import RxSwift
import RxCocoa

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
    fileprivate let dataStore: DataStore
    private let telemetryActionHandler: TelemetryActionHandler
    private let credentialProviderStore: CredentialProviderStore
    private let autoLockSupport: AutoLockSupport
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
         telemetryActionHandler: TelemetryActionHandler = TelemetryActionHandler(accountStore: AccountStore.shared),
         credentialProviderStore: CredentialProviderStore = .shared,
         autoLockSupport: AutoLockSupport = .shared,
         sizeClassStore: SizeClassStore = .shared) { // SizeClassStore needs to be initialized
        self.view = view
        self.dispatcher = dispatcher
        self.accountStore = accountStore
        self.telemetryStore = telemetryStore
        self.userDefaultStore = userDefaultStore
        self.dataStore = dataStore
        self.telemetryActionHandler = telemetryActionHandler
        self.credentialProviderStore = credentialProviderStore
        self.autoLockSupport = autoLockSupport

        self.accountStore.syncCredentials
            .filterNil()
            .bind { [weak self] (syncInfo) in
                self?.dispatcher.dispatch(action: DataStoreAction.updateCredentials(syncInfo: syncInfo))
            }
            .disposed(by: self.disposeBag)

        self.dispatcher.register
            .filterByType(class: CredentialStatusAction.self)
            .subscribe(onNext: { [weak self] action in
                switch action {
                case .extensionConfigured:
                    self?.view?.extensionContext.completeExtensionConfigurationRequest()
                case .loginSelected(let login):
                    self?.view?.extensionContext.completeRequest(withSelectedCredential: login.passwordCredential) { _ in
                        self?.dispatcher.dispatch(action: DataStoreAction.touch(id: login.id))
                    }
                case .cancelled(let error):
                    self?.cancelWith(error)
                }
            })
            .disposed(by: self.disposeBag)

        self.startTelemetry()
    }

    func extensionConfigurationRequested() {
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
        self.dataStore.locked
                .take(1)
                .bind { [weak self] locked in
                    if locked {
                        self?.dispatcher.dispatch(action: CredentialProviderAction.authenticationRequested)
                        self?.dispatcher.dispatch(action: CredentialStatusAction.cancelled(error: .userInteractionRequired))
                    } else {
                        self?.provideCredential(for: credentialIdentity)
                    }
                }
                .disposed(by: self.disposeBag)
    }

    func interfaceToAuthentication(for credentialIdentity: ASPasswordCredentialIdentity) {
        self.dataStore.locked
                .bind { [weak self] locked in
                    if locked {
                        self?.view?.displayWelcome()
                    } else {
                        self?.provideCredential(for: credentialIdentity)
                    }
                }
                .disposed(by: self.disposeBag)
    }

    func changeDisplay(traitCollection: UITraitCollection) {
        self.dispatcher.dispatch(action: SizeClassAction.changed(traitCollection: traitCollection))
    }

    func credentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        self.dataStore.locked
                .asDriver(onErrorJustReturn: true)
                .drive(onNext: { [weak self] locked in
                    if locked {
                        self?.dispatcher.dispatch(action: CredentialProviderAction.authenticationRequested)
                        self?.view?.displayWelcome()
                    } else {
                        self?.view?.displayItemList()
                    }
                })
                .disposed(by: self.disposeBag)
    }
}

@available(iOS 12, *)
extension CredentialProviderPresenter {
    private func provideCredential(for credentialIdentity: ASPasswordCredentialIdentity) {
        guard let id = credentialIdentity.recordIdentifier else {
            self.cancelWith(.credentialIdentityNotFound)
            return
        }

        self.dataStore.locked
                .filter { !$0 }
                .take(1)
                .flatMap { _ in self.dataStore.get(id) }
                .bind { [weak self] login in
                    guard let login = login else {
                        self?.cancelWith(.credentialIdentityNotFound)
                        return
                    }

                    self?.dispatcher.dispatch(action: CredentialStatusAction.loginSelected(login: login))
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

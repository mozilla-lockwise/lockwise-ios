/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AuthenticationServices
import RxSwift
import FxAClient
import RxCocoa
import LocalAuthentication

protocol CredentialWelcomeViewProtocol: BaseWelcomeViewProtocol, SpinnerAlertView { }

@available(iOS 12, *)
class CredentialWelcomePresenter: BaseWelcomePresenter {
    private weak var view: CredentialWelcomeViewProtocol? {
        return self.baseView as? CredentialWelcomeViewProtocol
    }

    private let credentialProviderStore: CredentialProviderStore
    private var authenticationBag = DisposeBag()

    private var okButtonObserver: AnyObserver<Void> {
        return Binder(self) { target, _ in
            self.dispatcher.dispatch(action: CredentialStatusAction.extensionConfigured)
        }.asObserver()
    }

    init(view: BaseWelcomeViewProtocol,
                  dispatcher: Dispatcher = .shared,
                  accountStore: AccountStore = .shared,
                  dataStore: DataStore = .shared,
                  lifecycleStore: LifecycleStore = .shared,
                  credentialProviderStore: CredentialProviderStore = .shared,
                  biometryManager: BiometryManager = BiometryManager()) {
        self.credentialProviderStore = credentialProviderStore

        super.init(view: view,
                   dispatcher: dispatcher,
                   accountStore: accountStore,
                   dataStore: dataStore,
                   lifecycleStore: lifecycleStore,
                   biometryManager: biometryManager)
    }

    override func onViewReady() {
        Observable.combineLatest(self.accountStore.syncCredentials, self.accountStore.profile)
                .take(1)
                .subscribe(onNext: { latest in
                    if latest.0 == nil && latest.1 == nil {
                        self.displayNotLoggedInMessage()
                    } else {
                        self.populateCredentials()
                    }
                }).disposed(by: self.disposeBag)

        self.credentialProviderStore.state
                .asDriver(onErrorJustReturn: .NotAllowed)
                .filter { $0 == CredentialProviderStoreState.Populating }
                .drive(onNext: { [weak self] _ in
                    self?.populateCredentials()
                })
                .disposed(by: self.disposeBag)
    }

    func onViewAppeared() {
        self.authenticationBag = DisposeBag()

        let delay = isRunningTest ? 0.0 : 1.0
        self.credentialProviderStore.displayAuthentication
            .filter { $0 }
            .delay(delay, scheduler: MainScheduler.instance)
            .flatMap { [weak self] _ -> Observable<Profile?> in
                guard let accountStore = self?.accountStore else {
                    return Observable.just(nil)
                }

                return accountStore.profile
            }
            .flatMap { [weak self] profile -> Single<Void> in
                guard let target = self else {
                    return Observable.never().asSingle()
                }

                let message = profile?.email ?? Constant.string.unlockPlaceholder

                return target.launchBiometrics(message: message)
            }
            .subscribe(
                onNext: { [weak self] _ in
                    self?.dispatcher.dispatch(action: DataStoreAction.unlock)
                    self?.dispatcher.dispatch(action: CredentialProviderAction.authenticated)
                }, onError: { [weak self] error in
                    if let error = error as? LAError,
                        error.code == LAError.Code.systemCancel {
                        return
                    }

                    self?.dispatcher.dispatch(action: CredentialStatusAction.userCanceled)
                }
            )
            .disposed(by: self.authenticationBag)
    }
}

@available(iOS 12, *)
extension CredentialWelcomePresenter {
    private func displayNotLoggedInMessage() {
        view?.displayAlertController(
                buttons: [AlertActionButtonConfiguration(
                        title: Constant.string.ok,
                        tapObserver: self.okButtonObserver,
                        style: UIAlertAction.Style.default)],
                title: Constant.string.signInRequired,
                message: String(format: Constant.string.signInRequiredBody, Constant.string.productName, Constant.string.productName),
                style: .alert,
                barButtonItem: nil)
    }

    private func populateCredentials() {
        let populated = self.credentialProviderStore.state
                .filter { $0 == CredentialProviderStoreState.Populated }
                .map { _ -> Void in return () }

        self.credentialProviderStore.state
                .asDriver(onErrorJustReturn: CredentialProviderStoreState.NotAllowed)
                .filter { $0 == CredentialProviderStoreState.Populating }
                .drive(onNext: { [weak self] _ in
                    guard let disposeBag = self?.disposeBag else { return }

                    self?.view?.displaySpinner(populated.asDriver(onErrorJustReturn: ()),
                                               bag: disposeBag,
                                               message: Constant.string.enablingAutofill,
                                               completionMessage: Constant.string.completedEnablingAutofill)
                })
                .disposed(by: self.disposeBag)

        populated
                .delay(Constant.number.displayStatusAlertLength, scheduler: MainScheduler.instance)
                .subscribe{ [weak self] _ in
                    self?.dispatcher.dispatch(action: CredentialStatusAction.extensionConfigured)
                }
                .disposed(by: self.disposeBag)

    }
}

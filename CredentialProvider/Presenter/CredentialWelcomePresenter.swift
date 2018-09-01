/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AuthenticationServices
import RxSwift
import RxCocoa

protocol CredentialWelcomeViewProtocol: BaseWelcomeViewProtocol, SpinnerAlertView, StatusAlertView { }

class CredentialWelcomePresenter: BaseWelcomePresenter {
    private weak var view: CredentialWelcomeViewProtocol? {
        return self.baseView as? CredentialWelcomeViewProtocol
    }
    
    private let credentialProviderStore: CredentialProviderStore

    private var okButtonObserver: AnyObserver<Void> {
        return Binder(self) { target, _ in
            if let url = URL(string: "lockbox://") {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }

            // TODO: Close the screen
            //self.view?.extensionContext.cancelRequest()
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
        Observable.combineLatest(self.accountStore.oauthInfo, self.accountStore.profile)
            .take(1)
            .subscribe(onNext: { latest in
            if latest.0 == nil && latest.1 == nil {
                self.displayNotLoggedInMessage()
            } else {
                self.populateCredentials()
            }
        }).disposed(by: self.disposeBag)
        
    }

    private func displayNotLoggedInMessage() {
        view?.displayAlertController(
            buttons: [AlertActionButtonConfiguration(
                title: Constant.string.signIn,
                tapObserver: self.okButtonObserver,
                style: UIAlertAction.Style.default)],
            title: Constant.string.signInRequired,
            message: String(format: Constant.string.signInRequiredBody, Constant.string.productName, Constant.string.productName, Constant.string.productName),
            style: .alert)
    }

    private func populateCredentials() {
        self.dispatcher.dispatch(action: CredentialProviderAction.refresh)

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
            .subscribe{ _ in
                self.dispatcher.dispatch(action: CredentialStatusAction.extensionConfigured)
            }
            .disposed(by: self.disposeBag)
    }
}

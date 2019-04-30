/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxOptional
import CoreGraphics
import MozillaAppServices

protocol WelcomeViewProtocol: BaseWelcomeViewProtocol {
    var loginButtonHidden: AnyObserver<Bool> { get }
    var firstTimeLoginMessageHidden: AnyObserver<Bool> { get }
    var firstTimeLearnMoreHidden: AnyObserver<Bool> { get }
    var firstTimeLearnMoreArrowHidden: AnyObserver<Bool> { get }
    var lockImageHidden: AnyObserver<Bool> { get }
    var unlockButtonHidden: AnyObserver<Bool> { get }
    var loginButtonPressed: ControlEvent<Void> { get }
    var learnMorePressed: ControlEvent<Void> { get }
    var unlockButtonPressed: ControlEvent<Void> { get }
}

class WelcomePresenter: BaseWelcomePresenter {
    private var userDefaultStore: UserDefaultStore

    weak var view: WelcomeViewProtocol? {
        return self.baseView as? WelcomeViewProtocol
    }

    init(view: WelcomeViewProtocol,
         dispatcher: Dispatcher = .shared,
         accountStore: AccountStore = AccountStore.shared,
         dataStore: DataStore = DataStore.shared,
         lifecycleStore: LifecycleStore = LifecycleStore.shared,
         biometryManager: BiometryManager = BiometryManager(),
         userDefaultStore: UserDefaultStore = UserDefaultStore.shared) {

        self.userDefaultStore = userDefaultStore

        super.init(view: view,
                   dispatcher: dispatcher,
                   accountStore: accountStore,
                   dataStore: dataStore,
                   lifecycleStore: lifecycleStore,
                   biometryManager: biometryManager)
    }

    override func onViewReady() {
        self.setupDisplay()
        self.setupBiometricLaunchers()

        self.view?.loginButtonPressed
                .subscribe(onNext: { [weak self] _ in
                    if self?.biometryManager.deviceAuthenticationAvailable ?? true {
                        self?.dispatcher.dispatch(action: LoginRouteAction.fxa)
                    } else {
                        self?.launchPasscodePrompt()
                    }
                })
                .disposed(by: self.disposeBag)

        self.view?.learnMorePressed
            .subscribe(onNext: { _ in
                self.dispatcher.dispatch(action: ExternalWebsiteRouteAction(
                        urlString: Constant.app.useLockboxFAQ,
                        title: Constant.string.learnMore,
                        returnRoute: LoginRouteAction.welcome))
            })
            .disposed(by: self.disposeBag)

        self.accountStore.hasOldAccountInformation
            .filter { $0 }
            .subscribe(onNext: {  [weak self] _ in
                self?.showOAuthUpgradeDialog()
            })
            .disposed(by: self.disposeBag)
    }
}

extension WelcomePresenter {
    private var skipButtonObserver: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: LoginRouteAction.fxa)
        }.asObserver()
    }

    private var setPasscodeButtonObserver: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: SettingLinkAction.touchIDPasscode)
        }.asObserver()
    }

    private var oauthLoginConfirmationObserver: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: LoginRouteAction.fxa)
            target.dispatcher.dispatch(action: AccountAction.oauthSignInMessageRead)
        }.asObserver()
    }

    private var passcodeButtonsConfiguration: [AlertActionButtonConfiguration] {
        return [
            AlertActionButtonConfiguration(
                    title: Constant.string.skip,
                    tapObserver: self.skipButtonObserver,
                    style: .cancel),
            AlertActionButtonConfiguration(
                    title: Constant.string.setPasscode,
                    tapObserver: self.setPasscodeButtonObserver,
                    style: .default)
        ]
    }

    private func setupBiometricLaunchers() {
        let lifecycleObservable = self.lifecycleStore.lifecycleEvents
                .filter { action -> Bool in
            return action == LifecycleAction.foreground
        }

        let lifecycleMindingLockedObservable = Observable.combineLatest(
                        self.accountStore.profile,
                        self.dataStore.locked.distinctUntilChanged(),
                        lifecycleObservable
                )
                .map { ($0.0, $0.1) }

        self.handleBiometrics(lifecycleMindingLockedObservable)

        guard let view = self.view else { return }

        let biometricButtonTapObservable = Observable.combineLatest(
                        self.accountStore.profile,
                        self.dataStore.locked.distinctUntilChanged(),
                        view.unlockButtonPressed.asObservable()
                )
                .map { ($0.0, $0.1) }

        self.handleBiometrics(biometricButtonTapObservable)

        // Launch the biometrics on cold start
        let coldStartObservable = Observable.combineLatest(
            self.accountStore.profile,
            self.dataStore.locked.distinctUntilChanged(),
            self.userDefaultStore.forceLock)
            .take(1)
            .filter { !$0.2 }
            .map { ($0.0, $0.1) }
        self.handleBiometrics(coldStartObservable)
    }

    private func launchPasscodePrompt() {
        self.view?.displayAlertController(
                buttons: self.passcodeButtonsConfiguration,
                title: Constant.string.notUsingPasscode,
                message: Constant.string.passcodeInformation,
                style: .alert,
                barButtonItem:  nil)
    }

    private func handleBiometrics(_ infoLockedObservable: Observable<(Profile?, Bool)>) {
        infoLockedObservable
                .filter { $0.1 }
                .map { $0.0 }
                .flatMap { [weak self] latest -> Single<Void> in
                    guard let target = self else {
                        return Observable.never().asSingle()
                    }

                    return target.launchBiometrics(message: latest?.email ?? Constant.string.unlockPlaceholder)
                        .catchError { _ in
                            // ignore errors from local authentication
                            return Observable.never().asSingle()
                        }
                }
                .subscribe(onNext: { [weak self] _ in
                    self?.dispatcher.dispatch(action: DataStoreAction.unlock)
                })
                .disposed(by: self.disposeBag)
    }

    private func setupDisplay() {
        let lockedObservable = self.dataStore.locked.distinctUntilChanged()

        guard let view = self.view else { return }

        let firstRunHiddenObservers = [
            view.firstTimeLoginMessageHidden,
            view.firstTimeLearnMoreHidden,
            view.firstTimeLearnMoreArrowHidden,
            view.loginButtonHidden
        ]

        let lockScreenHiddenObservers = [
            view.lockImageHidden,
            view.unlockButtonHidden
        ]

        for observer in firstRunHiddenObservers {
            lockedObservable
                    .bind(to: observer)
                    .disposed(by: self.disposeBag)
        }

        for observer in lockScreenHiddenObservers {
            lockedObservable
                    .map { !$0 }
                    .bind(to: observer)
                    .disposed(by: self.disposeBag)
        }
    }

    func showOAuthUpgradeDialog() {
        self.view?.displayAlertController(
            buttons: [
                AlertActionButtonConfiguration(
                    title: Constant.string.continueText,
                    tapObserver: self.oauthLoginConfirmationObserver,
                    style: .default)
            ],
            title: Constant.string.reauthenticationRequired,
            message: Constant.string.appUpdateDisclaimer,
            style: .alert,
            barButtonItem: nil)
    }
}

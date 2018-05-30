/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxOptional
import CoreGraphics

protocol WelcomeViewProtocol: class, AlertControllerView {
    var loginButtonPressed: ControlEvent<Void> { get }
    var learnMorePressed: ControlEvent<Void> { get }
    var loginButtonHidden: AnyObserver<Bool> { get }
    var firstTimeLoginMessageHidden: AnyObserver<Bool> { get }
    var firstTimeLearnMoreHidden: AnyObserver<Bool> { get }
}

struct LockedEnabled {
    let appLocked: Bool
    let biometricsEnabled: Bool
}

extension LockedEnabled: Equatable {
    static func ==(lhs: LockedEnabled, rhs: LockedEnabled) -> Bool {
        return lhs.appLocked == rhs.appLocked && lhs.biometricsEnabled == rhs.biometricsEnabled
    }
}

class WelcomePresenter {
    private weak var view: WelcomeViewProtocol?

    private let routeActionHandler: RouteActionHandler
    private let dataStoreActionHandler: DataStoreActionHandler
    private let userInfoActionHandler: UserInfoActionHandler
    private let linkActionHandler: LinkActionHandler
    private let userInfoStore: UserInfoStore
    private let dataStore: DataStore
    private let lifecycleStore: LifecycleStore
    private let biometryManager: BiometryManager
    private let disposeBag = DisposeBag()

    init(view: WelcomeViewProtocol,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         dataStoreActionHandler: DataStoreActionHandler = DataStoreActionHandler.shared,
         userInfoActionHandler: UserInfoActionHandler = UserInfoActionHandler.shared,
         linkActionHandler: LinkActionHandler = LinkActionHandler.shared,
         userInfoStore: UserInfoStore = UserInfoStore.shared,
         dataStore: DataStore = DataStore.shared,
         lifecycleStore: LifecycleStore = LifecycleStore.shared,
         biometryManager: BiometryManager = BiometryManager()) {
        self.view = view
        self.routeActionHandler = routeActionHandler
        self.dataStoreActionHandler = dataStoreActionHandler
        self.userInfoActionHandler = userInfoActionHandler
        self.linkActionHandler = linkActionHandler
        self.userInfoStore = userInfoStore
        self.dataStore = dataStore
        self.lifecycleStore = lifecycleStore
        self.biometryManager = biometryManager
    }

    func onViewReady() {
        let lockedObservable = self.dataStore.locked.distinctUntilChanged()

        if let view = self.view {
            lockedObservable
                    .bind(to: view.firstTimeLoginMessageHidden)
                    .disposed(by: self.disposeBag)

            lockedObservable
                    .bind(to: view.firstTimeLearnMoreHidden)
                    .disposed(by: self.disposeBag)

            lockedObservable
                    .bind(to: view.loginButtonHidden)
                    .disposed(by: self.disposeBag)
        }

        let lifecycleObservable = self.lifecycleStore.lifecycleFilter
                .filter { action -> Bool in
            return action == LifecycleAction.foreground
        }

        let lifecycleMindingLockedObservable = Observable.combineLatest(
                        self.userInfoStore.profileInfo,
                        self.dataStore.locked.distinctUntilChanged(),
                        lifecycleObservable
                )
                .map {
                    ($0.0, $0.1)
                }

        self.handleBiometrics(lifecycleMindingLockedObservable)

        let standardLockedObservable = Observable.combineLatest(
                self.userInfoStore.profileInfo,
                self.dataStore.locked.distinctUntilChanged()
        )

        self.handleBiometrics(standardLockedObservable)

        self.view?.loginButtonPressed
                .subscribe(onNext: { [weak self] _ in
                    if self?.biometryManager.deviceAuthenticationAvailable ?? true {
                        self?.routeActionHandler.invoke(LoginRouteAction.fxa)
                    } else {
                        self?.launchPasscodePrompt()
                    }
                })
                .disposed(by: self.disposeBag)

        self.view?.learnMorePressed
            .subscribe(onNext: { _ in
                self.routeActionHandler.invoke(ExternalWebsiteRouteAction(
                        urlString: Constant.app.useLockboxFAQ,
                        title: Constant.string.learnMore,
                        returnRoute: LoginRouteAction.welcome))
            })
            .disposed(by: self.disposeBag)

        self.userInfoActionHandler.invoke(.load)
    }
}

extension WelcomePresenter {
    private var skipButtonObserver: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(LoginRouteAction.fxa)
        }.asObserver()
    }

    private var setPasscodeButtonObserver: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.linkActionHandler.invoke(SettingLinkAction.touchIDPasscode)
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

    private func launchPasscodePrompt() {
        self.view?.displayAlertController(
                buttons: self.passcodeButtonsConfiguration,
                title: Constant.string.notUsingPasscode,
                message: Constant.string.passcodeInformation,
                style: .alert)
    }

    private func handleBiometrics(_ infoLockedObservable: Observable<(ProfileInfo?, Bool)>) {
        infoLockedObservable
                .filter { $0.1 }
                .map { $0.0 }
                .flatMap { [weak self] latest -> Single<Void> in
                    guard let target = self else {
                        return Observable.never().asSingle()
                    }

                    if !target.biometryManager.deviceAuthenticationAvailable {
                        return Single.just(())
                    }

                    return target.biometryManager.authenticateWithMessage(latest?.email ?? Constant.string.unlockPlaceholder) // swiftlint:disable:this line_length
                            .catchError { _ in
                                // ignore errors from local authentication
                                return Observable.never().asSingle()
                            }
                }
                .subscribe(onNext: { [weak self] _ in
                    self?.dataStoreActionHandler.invoke(.unlock)
                })
                .disposed(by: self.disposeBag)
    }
}

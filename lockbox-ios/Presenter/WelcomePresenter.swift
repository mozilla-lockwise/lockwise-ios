/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxOptional
import CoreGraphics

protocol WelcomeViewProtocol: class {
    var loginButtonPressed: ControlEvent<Void> { get }
    var biometricSignInButtonPressed: ControlEvent<Void> { get }
    var firstTimeLoginMessageHidden: AnyObserver<Bool> { get }
    var biometricAuthenticationPromptHidden: AnyObserver<Bool> { get }
    var biometricSignInText: AnyObserver<String?> { get }
    var biometricImageName: AnyObserver<String> { get }
    var fxAButtonTopSpace: AnyObserver<CGFloat> { get }
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
    private let settingActionHandler: SettingActionHandler
    private let userInfoStore: UserInfoStore
    private let userDefaults: UserDefaults
    private let biometryManager: BiometryManager
    private let disposeBag = DisposeBag()

    init(view: WelcomeViewProtocol,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         settingActionHandler: SettingActionHandler = SettingActionHandler.shared,
         userInfoStore: UserInfoStore = UserInfoStore.shared,
         userDefaults: UserDefaults = UserDefaults.standard,
         biometryManager: BiometryManager = BiometryManager()) {
        self.view = view
        self.routeActionHandler = routeActionHandler
        self.settingActionHandler = settingActionHandler
        self.userInfoStore = userInfoStore
        self.userDefaults = userDefaults
        self.biometryManager = biometryManager
    }

    func onViewReady() {
        let biometricButtonText = self.biometryManager.usesFaceID ? Constant.string.signInFaceID : Constant.string.signInTouchID // swiftlint:disable:this line_length
        let biometricImageName = self.biometryManager.usesFaceID ? "face" : "fingerprint"

        self.view?.biometricSignInText.onNext(biometricButtonText)
        self.view?.biometricImageName.onNext(biometricImageName)

        let lockedObservable = self.userDefaults.onLock.distinctUntilChanged()
        let biometricsObservable = self.userDefaults.onBiometricsEnabled.distinctUntilChanged()

        if let view = self.view {
            lockedObservable
                    .bind(to: view.firstTimeLoginMessageHidden)
                    .disposed(by: self.disposeBag)

            Observable.combineLatest(lockedObservable, biometricsObservable)
                    .map {
                        LockedEnabled(appLocked: $0.0, biometricsEnabled: $0.1)
                    }
                    .distinctUntilChanged()
                    .map { latest -> Bool in
                        if !self.biometryManager.usesFaceID && !self.biometryManager.usesTouchID {
                            return true
                        }

                        return !latest.appLocked ? true : !latest.biometricsEnabled
                    }
                    .bind(to: view.biometricAuthenticationPromptHidden)
                    .disposed(by: self.disposeBag)

            lockedObservable
                    .map {
                        $0 ? Constant.number.fxaButtonTopSpaceUnlock : Constant.number.fxaButtonTopSpaceFirstLogin
                    }
                    .bind(to: view.fxAButtonTopSpace)
                    .disposed(by: self.disposeBag)

            Observable.combineLatest(self.userInfoStore.profileInfo.filterNil(), view.biometricSignInButtonPressed)
                    .flatMap {
                        self.biometryManager.authenticateWithMessage($0.0.email)
                    }
                    .catchError { _ in
                        // we don't care about errors with local authentication because users can fall back to FxA
                        return Observable.empty()
                    }
                    .subscribe(onNext: { _ in
                        self.settingActionHandler.invoke(SettingAction.visualLock(locked: false))
                        self.routeActionHandler.invoke(MainRouteAction.list)
                    })
                    .disposed(by: self.disposeBag)
        }

        self.view?.loginButtonPressed
                .subscribe(onNext: { _ in
                    self.routeActionHandler.invoke(LoginRouteAction.fxa)
                })
                .disposed(by: self.disposeBag)
    }
}

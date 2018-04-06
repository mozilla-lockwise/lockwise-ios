/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import CoreGraphics
import LocalAuthentication

protocol WelcomeViewProtocol: class {
    var loginButtonPressed: ControlEvent<Void> { get }
    var firstTimeLoginMessageHidden: AnyObserver<Bool> { get }
    var biometricAuthenticationPromptHidden: AnyObserver<Bool> { get }
    var biometricSignInText: AnyObserver<String?> { get }
    var biometricImageName: AnyObserver<String> { get }
    var fxAButtonTopSpace: AnyObserver<CGFloat> { get }
}

struct LockedEnabled {
    let locked: Bool
    let enabled: Bool
}

extension LockedEnabled: Equatable {
    static func ==(lhs: LockedEnabled, rhs: LockedEnabled) -> Bool {
        return lhs.locked == rhs.locked && lhs.enabled == rhs.enabled
    }
}

class WelcomePresenter {
    private weak var view: WelcomeViewProtocol?

    private let routeActionHandler: RouteActionHandler
    private let userDefaults: UserDefaults
    private let disposeBag = DisposeBag()

    init(view: WelcomeViewProtocol,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         userDefaults: UserDefaults = UserDefaults.standard) {
        self.view = view
        self.routeActionHandler = routeActionHandler
        self.userDefaults = userDefaults
    }

    func onViewReady() {
        let biometricButtonText = LAContext.usesFaceId ? Constant.string.signInFaceID : Constant.string.signInTouchID
        let biometricImageName = LAContext.usesFaceId ? "face" : "fingerprint"

        self.view?.biometricSignInText.onNext(biometricButtonText)
        self.view?.biometricImageName.onNext(biometricImageName)

        let lockedObservable = self.userDefaults.onLock.distinctUntilChanged()
        let biometricsObservable = self.userDefaults.onBiometricsEnabled.distinctUntilChanged()

        if let view = self.view {
            lockedObservable
                    .bind(to: view.firstTimeLoginMessageHidden)
                    .disposed(by: self.disposeBag)

            Observable.combineLatest(lockedObservable, biometricsObservable)
                    .map { LockedEnabled(locked: $0.0, enabled: $0.1) }
                    .distinctUntilChanged()
                    .map { latest -> Bool in
                        !latest.locked ? true : !latest.enabled
                    }
                    .bind(to: view.biometricAuthenticationPromptHidden)
                    .disposed(by: self.disposeBag)

            lockedObservable
                    .map {
                        $0 ? Constant.number.fxaButtonTopSpaceUnlock : Constant.number.fxaButtonTopSpaceFirstLogin
                    }
                    .bind(to: view.fxAButtonTopSpace)
                    .disposed(by: self.disposeBag)
        }

        self.view?.loginButtonPressed
                .subscribe(onNext: { _ in
                    self.routeActionHandler.invoke(LoginRouteAction.fxa)
                })
                .disposed(by: self.disposeBag)
    }
}

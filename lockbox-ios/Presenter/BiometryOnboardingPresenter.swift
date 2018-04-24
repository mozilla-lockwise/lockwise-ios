/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

protocol BiometryOnboardingViewProtocol: class {
    var enableTapped: Observable<Void> { get }
    var notNowTapped: Observable<Void> { get }
    var hasFaceID: Bool { get }

    func setBiometricsImageName(_ name: String)
    func setBiometricsTitle(_ title: String)
    func setBiometricsSubTitle(_ subTitle: String)
}

class BiometryOnboardingPresenter {
    private weak var view: BiometryOnboardingViewProtocol?
    private let routeActionHandler: RouteActionHandler
    private let settingActionHandler: SettingActionHandler
    private let biometryManager: BiometryManager
    private let disposeBag = DisposeBag()

    init(view: BiometryOnboardingViewProtocol,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         settingActionHandler: SettingActionHandler = SettingActionHandler.shared,
         biometryManager: BiometryManager = BiometryManager()) {
        self.view = view
        self.routeActionHandler = routeActionHandler
        self.settingActionHandler = settingActionHandler
        self.biometryManager = biometryManager
    }

    func onViewReady() {
        self.setUpContent()

        self.view?.enableTapped
                .subscribe { [weak self] (_) in
                    if let view = self?.view,
                       view.hasFaceID {
                        self?.initialFaceIDAuth()
                    }

                    self?.settingActionHandler.invoke(SettingAction.biometricLogin(enabled: true))
                    self?.routeActionHandler.invoke(MainRouteAction.list)
                }
                .disposed(by: self.disposeBag)

        self.view?.notNowTapped
                .subscribe { [weak self] (_) in
                    self?.routeActionHandler.invoke(MainRouteAction.list)
                }
                .disposed(by: self.disposeBag)
    }
}

extension BiometryOnboardingPresenter {
    fileprivate func setUpContent() {
        if let view = self.view {
            var imageName: String
            var pageTitle: String
            var subtitle: String

            if view.hasFaceID {
                imageName = "face-large"
                pageTitle = Constant.string.onboardingFaceIDHeader
                subtitle = Constant.string.onboardingFaceIDSubtitle
            } else {
                imageName = "fingerprint-large"
                pageTitle = Constant.string.onboardingTouchIDHeader
                subtitle = Constant.string.onboardingTouchIDSubtitle
            }

            view.setBiometricsImageName(imageName)
            view.setBiometricsTitle(pageTitle)
            view.setBiometricsSubTitle(subtitle)
        }
    }

    fileprivate func initialFaceIDAuth() {
        self.biometryManager.authenticateWithBiometrics(message: "")
                .subscribe()
                .disposed(by: self.disposeBag)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

protocol BiometryOnboardingViewProtocol: class {
    var enableTapped: Observable<Void> { get }
    var notNowTapped: Observable<Void> { get }

    func setBiometricsImageName(_ name: String)
    func setBiometricsTitle(_ title: String)
    func setBiometricsSubTitle(_ subTitle: String)
}

class BiometryOnboardingPresenter {
    private weak var view: BiometryOnboardingViewProtocol?

    init(view: BiometryOnboardingViewProtocol) {
        self.view = view
    }

    func onViewReady() {

    }
}
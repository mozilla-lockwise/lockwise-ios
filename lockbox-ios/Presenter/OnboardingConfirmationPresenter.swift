/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

protocol OnboardingConfirmationViewProtocol: class {
    var finishButtonTapped: Observable<Void> { get }
}

class OnboardingConfirmationPresenter {
    private weak var view: OnboardingConfirmationViewProtocol?
    private let dispatcher: Dispatcher
    private let disposeBag = DisposeBag()

    init(view: OnboardingConfirmationViewProtocol,
         dispatcher: Dispatcher = .shared) {
        self.view = view
        self.dispatcher = dispatcher
    }

    func onViewReady() {
        self.view?.finishButtonTapped
                .subscribe(onNext: { _ in
                    self.dispatcher.dispatch(action: MainRouteAction.list)
                    self.dispatcher.dispatch(action: OnboardingStatusAction(onboardingInProgress: false))
                })
                .disposed(by: self.disposeBag)
    }

}

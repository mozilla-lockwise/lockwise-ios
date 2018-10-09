/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

protocol AutofillOnboardingViewProtocol: class {
    var skipButtonTapped: Observable<Void> { get }
    var setupAutofillTapped: Observable<Void> { get }
}

class AutofillOnboardingPresenter {
    private weak var view: AutofillOnboardingViewProtocol?
    private let dispatcher: Dispatcher
    private let disposeBag = DisposeBag()

    init(view: AutofillOnboardingViewProtocol,
         dispatcher: Dispatcher = .shared) {
        self.view = view
        self.dispatcher = dispatcher
    }

    func onViewReady() {
        self.view?.skipButtonTapped
            .subscribe(onNext: { _ in
                self.dispatcher.dispatch(action: LoginRouteAction.onboardingConfirmation)
            })
            .disposed(by: self.disposeBag)

        self.view?.setupAutofillTapped
            .subscribe(onNext: { _ in
                self.dispatcher.dispatch(action: LoginRouteAction.autofillInstructions)
            })
            .disposed(by: self.disposeBag)
    }
}

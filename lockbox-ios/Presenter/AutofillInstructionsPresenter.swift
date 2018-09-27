/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

protocol OnboardingInstructionsViewProtocol: class {
    var finishButtonTapped: Observable<Void> { get }
}

class AutofillInstructionsPresenter {
    private weak var view: OnboardingInstructionsViewProtocol?
    private let dispatcher: Dispatcher
    private let disposeBag = DisposeBag()

    init(view: OnboardingInstructionsViewProtocol,
         dispatcher: Dispatcher = .shared) {
        self.view = view
        self.dispatcher = dispatcher
    }

    func onViewReady() {
        self.view?.finishButtonTapped
            .subscribe(onNext: { _ in
                self.dispatcher.dispatch(action: SettingRouteAction.list)
            })
            .disposed(by: self.disposeBag)
    }
}

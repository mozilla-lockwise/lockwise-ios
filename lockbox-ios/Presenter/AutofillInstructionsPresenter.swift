/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

protocol AutofillInstructionsViewProtocol: class {
    var finishButtonTapped: Observable<Void> { get }
}

class AutofillInstructionsPresenter {
    private weak var view: AutofillInstructionsViewProtocol?
    private let dispatcher: Dispatcher
    private let disposeBag = DisposeBag()
    private let routeStore: RouteStore

    init(view: AutofillInstructionsViewProtocol,
         dispatcher: Dispatcher = .shared,
         routeStore: RouteStore = RouteStore.shared) {
        self.view = view
        self.dispatcher = dispatcher
        self.routeStore = routeStore
    }

    func onViewReady() {
        self.view?.finishButtonTapped
            .subscribe(onNext: { _ in
                self.routeStore.onboarding
                    .take(1)
                    .bind(onNext: { (isOnboarding) in
                        self.dispatcher.dispatch(action: isOnboarding ?
                            LoginRouteAction.onboardingConfirmation : SettingRouteAction.list)
                    }).disposed(by: self.disposeBag)
            })
            .disposed(by: self.disposeBag)
    }
}

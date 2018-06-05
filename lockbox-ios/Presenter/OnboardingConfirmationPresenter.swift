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
    private let routeActionHandler: RouteActionHandler
    private let disposeBag = DisposeBag()

    init(view: OnboardingConfirmationViewProtocol,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared) {
        self.view = view
        self.routeActionHandler = routeActionHandler
    }

    func onViewReady() {
        self.view?.finishButtonTapped
                .subscribe(onNext: { _ in
                    self.routeActionHandler.invoke(MainRouteAction.list)
                })
                .disposed(by: self.disposeBag)
    }

    func onEncryptionLinkTapped() {
        self.routeActionHandler.invoke(
                ExternalWebsiteRouteAction(
                        urlString: Constant.app.securityFAQ,
                        title: Constant.string.faq,
                        returnRoute: LoginRouteAction.onboardingConfirmation)
        )
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

protocol WelcomeViewProtocol: class {
    var loginButtonPressed:ControlEvent<Void> { get }
}

class WelcomePresenter {
    private weak var view: WelcomeViewProtocol?

    private let routeActionHandler:RouteActionHandler
    private let disposeBag = DisposeBag()

    init(view: WelcomeViewProtocol,
         routeActionHandler:RouteActionHandler = RouteActionHandler.shared) {
        self.view = view
        self.routeActionHandler = routeActionHandler
    }

    func onViewReady() {
        self.view?.loginButtonPressed
                .subscribe(onNext: { _ in
                    self.routeActionHandler.invoke(LoginRouteAction.fxa)
                })
                .disposed(by: self.disposeBag)
    }
}

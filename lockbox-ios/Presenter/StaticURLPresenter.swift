/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxCocoa
import RxSwift

protocol StaticURLViewProtocol: class {
    var returnRoute: RouteAction { get }
    var closeTapped: Observable<Void>? { get }
}

class StaticURLPresenter {
    private weak var view: StaticURLViewProtocol?

    private let routeActionHandler: RouteActionHandler
    private let disposeBag = DisposeBag()

    init(view: StaticURLViewProtocol,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared) {
        self.view = view
        self.routeActionHandler = routeActionHandler
    }

    func onViewReady() {
        self.view?.closeTapped?
                .subscribe(onNext: { [weak self] _ in
                    if let routeAction = self?.view?.returnRoute {
                        self?.routeActionHandler.invoke(routeAction)
                    }
                })
                .disposed(by: self.disposeBag)
    }
}

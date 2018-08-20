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

    private let dispatcher: Dispatcher
    private let disposeBag = DisposeBag()

    init(view: StaticURLViewProtocol,
         dispatcher: Dispatcher = .shared) {
        self.view = view
        self.dispatcher = dispatcher
    }

    func onViewReady() {
        self.view?.closeTapped?
                .subscribe(onNext: { [weak self] _ in
                    if let routeAction = self?.view?.returnRoute {
                        self?.dispatcher.dispatch(action: routeAction)
                    }
                })
                .disposed(by: self.disposeBag)
    }
}

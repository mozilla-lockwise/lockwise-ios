/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxCocoa
import RxSwift

protocol StaticURLViewProtocol: class {
    var returnRoute: RouteAction { get }
    var closeTapped: Observable<Void>? { get }
    var retryButtonTapped: Observable<Void> { get }
    var networkDisclaimerHidden: AnyObserver<Bool> { get }
    func reload()
}

class StaticURLPresenter {
    private weak var view: StaticURLViewProtocol?

    private let dispatcher: Dispatcher
    private let networkStore: NetworkStore
    private let disposeBag = DisposeBag()

    init(view: StaticURLViewProtocol,
         dispatcher: Dispatcher = .shared,
         networkStore: NetworkStore = .shared) {
        self.view = view
        self.dispatcher = dispatcher
        self.networkStore = networkStore
    }

    func onViewReady() {
        self.view?.closeTapped?
                .subscribe(onNext: { [weak self] _ in
                    if let routeAction = self?.view?.returnRoute {
                        self?.dispatcher.dispatch(action: routeAction)
                    }
                })
                .disposed(by: self.disposeBag)

        self.networkStore.connectedToNetwork
                .bind(to: view!.networkDisclaimerHidden)
                .disposed(by: self.disposeBag)

        self.view?.retryButtonTapped
                .map { _ in NetworkAction.retry }
                .subscribe(onNext: { self.dispatcher.dispatch(action: $0) })
                .disposed(by: self.disposeBag)

        self.networkStore.connectedToNetwork
                .distinctUntilChanged()
                .filter { $0 }
                .bind { _ in self.view?.reload()}
                .disposed(by: self.disposeBag)
    }
}

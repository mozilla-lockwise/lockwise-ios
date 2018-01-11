/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

protocol RootViewProtocol: class {
    func showWelcomeView()
    func showFxA()

    func showItemList()
    func showItemDetail(itemId:String)
}

class RoutePresenter {
    private weak var view: RootViewProtocol?
    private let disposeBag = DisposeBag()

    init(view: RootViewProtocol) {
        self.view = view

        RouteStore.shared.onRoute
                .filterByType(class: LoginRouteAction.self)
                .bind(to: showLogin)
                .disposed(by: disposeBag)

        RouteStore.shared.onRoute
                .filterByType(class: MainRouteAction.self)
                .bind(to: showList)
                .disposed(by: disposeBag)
    }

    fileprivate var showLogin:AnyObserver<LoginRouteAction> {
        return Binder(self) { target, loginAction in
            switch loginAction {
                case .login:
                    self.view!.showWelcomeView()
                case .fxa:
                    self.view!.showFxA()
            }
        }.asObserver()
    }

    fileprivate var showList:AnyObserver<MainRouteAction> {
        return Binder(self) { target, mainAction in
            switch mainAction {
            case .list:
                self.view!.showItemList()
            case .detail(let itemId):
                self.view!.showItemDetail(itemId: itemId)
            }
        }.asObserver()
    }
}
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

protocol ItemListViewProtocol: class {
    func displayItems(_ items: [Item])
    func displayEmptyStateMessaging()
    func hideEmptyStateMessaging()
}

class ItemListPresenter {
    private weak var view: ItemListViewProtocol?
    private var routeActionHandler: RouteActionHandler
    private var dataStore: DataStore
    private var disposeBag = DisposeBag()

    lazy private(set) var itemSelectedObserver: AnyObserver<Item> = {
        return Binder(self) { target, item in
            guard let id = item.id else { return }

            target.routeActionHandler.invoke(MainRouteAction.detail(itemId: id))
        }.asObserver()
    }()

    init(view: ItemListViewProtocol,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         dataStore: DataStore = DataStore.shared) {
        self.view = view
        self.routeActionHandler = routeActionHandler
        self.dataStore = dataStore
    }

    func onViewReady() {
        self.dataStore.onItemList
                .subscribe(onNext: { items in
                    if items.isEmpty {
                        self.view?.displayEmptyStateMessaging()
                    } else {
                        self.view?.hideEmptyStateMessaging()
                        self.view?.displayItems(items)
                    }
                })
                .disposed(by: self.disposeBag)
    }
}

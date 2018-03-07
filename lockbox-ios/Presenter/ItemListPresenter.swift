/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

protocol ItemListViewProtocol: class {
    func bind(items: Driver<[ItemSectionModel]>)
    func displayEmptyStateMessaging()
    func hideEmptyStateMessaging()
}

class ItemListPresenter {
    private weak var view: ItemListViewProtocol?
    private var routeActionHandler: RouteActionHandler
    private var dataStore: DataStore
    private var disposeBag = DisposeBag()

    lazy private(set) var itemSelectedObserver: AnyObserver<String?> = {
        return Binder(self) { target, itemId in
            guard let id = itemId else {
                return
            }

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
        let listDriver = self.dataStore.onItemList
                .do(onNext: { items in
                    if items.isEmpty {
                        self.view?.displayEmptyStateMessaging()
                    } else {
                        self.view?.hideEmptyStateMessaging()
                    }
                })
                .filter { items in
                    return !items.isEmpty
                }
                .map { items -> [ItemSectionModel] in
                    return [ItemSectionModel(model: 0, items: self.configurationsFromItems(items))]
                }
                .asDriver(onErrorJustReturn: [])

        self.view?.bind(items: listDriver)
    }
}

extension ItemListPresenter {
    // The typecasting and force-cast in this function are due to a bug in the Swift compiler that will be fixed in
    // the Swift 4.1 release.
    fileprivate func configurationsFromItems<T: IdentifiableType & Equatable>(_ items: [Item]) -> [T] {
        return items.map { item -> ItemCellConfiguration in
            let titleText = item.title ?? ""
            let usernameEmpty = item.entry.username == "" || item.entry.username == nil
            let usernameText = usernameEmpty ? Constant.string.usernamePlaceholder : item.entry.username!

            return ItemCellConfiguration(title: titleText, username: usernameText, id: item.id)
        } as! [T] // swiftlint:disable:this force_cast
    }
}

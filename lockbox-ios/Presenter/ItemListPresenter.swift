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

struct ItemListText {
    let items: [Item]
    let text: String
}

extension ItemListText: Equatable {
    static func ==(lhs: ItemListText, rhs: ItemListText) -> Bool {
        return lhs.items == rhs.items && lhs.text == rhs.text
    }
}

class ItemListPresenter {
    private weak var view: ItemListViewProtocol?
    private var routeActionHandler: RouteActionHandler
    private var dataStore: DataStore
    private var disposeBag = DisposeBag()
    private let filterTextSubject = BehaviorSubject<String>(value: "")

    lazy private(set) var itemSelectedObserver: AnyObserver<String?> = {
        return Binder(self) { target, itemId in
            guard let id = itemId else {
                return
            }

            target.routeActionHandler.invoke(MainRouteAction.detail(itemId: id))
        }.asObserver()
    }()

    lazy private(set) var filterTextObserver: AnyObserver<String> = {
        return self.filterTextSubject.asObserver()
    }()

    init(view: ItemListViewProtocol,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         dataStore: DataStore = DataStore.shared) {
        self.view = view
        self.routeActionHandler = routeActionHandler
        self.dataStore = dataStore
    }

    func onViewReady() {
        let listDriver = Observable.combineLatest(self.dataStore.onItemList, self.filterTextSubject.asObservable())
                .map { (latest: ([Item], String)) -> ItemListText in
                    return ItemListText(items: latest.0, text: latest.1)
                }
                .distinctUntilChanged()
                .do(onNext: { latest in
                    if latest.items.isEmpty {
                        self.view?.displayEmptyStateMessaging()
                    } else {
                        self.view?.hideEmptyStateMessaging()
                    }
                })
                .filter { latest in
                    return !latest.items.isEmpty
                }
                .map { (latest: ItemListText) -> [Item] in
                    if latest.text.isEmpty {
                        return latest.items
                    }

                    return latest.items.filter { item -> Bool in
                        return item.entry.username?.localizedCaseInsensitiveContains(latest.text) ?? false ||
                                item.origins.first?.localizedCaseInsensitiveContains(latest.text) ?? false ||
                                item.title?.localizedCaseInsensitiveContains(latest.text) ?? false
                    }
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
        let searchCell = [ItemListCellConfiguration.Search]

        let itemCells = items.map { item -> ItemListCellConfiguration in
            let titleText = item.title ?? ""
            let usernameEmpty = item.entry.username == "" || item.entry.username == nil
            let usernameText = usernameEmpty ? Constant.string.usernamePlaceholder : item.entry.username!

            return ItemListCellConfiguration.Item(title: titleText, username: usernameText, id: item.id)
        }

        return searchCell + itemCells as! [T] // swiftlint:disable:this force_cast
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

protocol ItemListViewProtocol: class, AlertControllerView {
    func bind(items: Driver<[ItemSectionModel]>)
    func bind(sortingButtonTitle: Driver<String>)
    func displayEmptyStateMessaging()
    func hideEmptyStateMessaging()
    func dismissKeyboard()
    func displayFilterCancelButton()
    func hideFilterCancelButton()
}

struct ItemListTextSort {
    let items: [Item]
    let text: String
    let sortingOption: ItemListSortingAction
}

extension ItemListTextSort: Equatable {
    static func ==(lhs: ItemListTextSort, rhs: ItemListTextSort) -> Bool {
        return lhs.items == rhs.items &&
                lhs.text == rhs.text &&
                lhs.sortingOption == rhs.sortingOption
    }
}

class ItemListPresenter {
    private weak var view: ItemListViewProtocol?
    private var routeActionHandler: RouteActionHandler
    private var itemListDisplayActionHandler: ItemListDisplayActionHandler
    private var dataStore: DataStore
    private var itemListDisplayStore: ItemListDisplayStore
    private var disposeBag = DisposeBag()

    lazy private(set) var itemSelectedObserver: AnyObserver<String?> = {
        return Binder(self) { target, itemId in
            guard let id = itemId else {
                return
            }

            target.routeActionHandler.invoke(MainRouteAction.detail(itemId: id))
        }.asObserver()
    }()

    lazy private(set) var onSettingsTapped: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(SettingRouteAction.list)
            }.asObserver()
    }()

    lazy private(set) var filterTextObserver: AnyObserver<String> = {
        return Binder(self) { target, filterText in
            target.itemListDisplayActionHandler.invoke(ItemListFilterAction(filteringText: filterText))
        }.asObserver()
    }()

    lazy private(set) var filterCancelObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dismissKeyboard()
        }.asObserver()
    }()

    lazy private(set) var sortingButtonObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.view?.displayAlertController(buttons: [
                                AlertActionButtonConfiguration(
                                    title: Constant.string.alphabetically,
                                    tapObserver: target.alphabeticSortObserver,
                                    style: .default),
                                AlertActionButtonConfiguration(
                                    title: Constant.string.recentlyUsed,
                                    tapObserver: target.recentlyUsedSortObserver,
                                    style: .default),
                                AlertActionButtonConfiguration(
                                    title: Constant.string.cancel,
                                    tapObserver: nil,
                                    style: .cancel)],
                                                title: Constant.string.sortEntries,
                                                message: nil,
                                                style: .actionSheet)
            }.asObserver()
    }()

    lazy private var alphabeticSortObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.itemListDisplayActionHandler.invoke(ItemListSortingAction.alphabetically)
        }.asObserver()
    }()

    lazy private var recentlyUsedSortObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.itemListDisplayActionHandler.invoke(ItemListSortingAction.recentlyUsed)
        }.asObserver()
    }()

    init(view: ItemListViewProtocol,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         itemListDisplayActionHandler: ItemListDisplayActionHandler = ItemListDisplayActionHandler.shared,
         dataStore: DataStore = DataStore.shared,
         itemListDisplayStore: ItemListDisplayStore = ItemListDisplayStore.shared) {
        self.view = view
        self.routeActionHandler = routeActionHandler
        self.itemListDisplayActionHandler = itemListDisplayActionHandler
        self.dataStore = dataStore
        self.itemListDisplayStore = itemListDisplayStore
    }

    func onViewReady() {
        let itemListObservable = self.dataStore.onItemList
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

        let itemSortObservable = self.itemListDisplayStore.listDisplay
                .filterByType(class: ItemListSortingAction.self)

        let filterTextObservable = self.itemListDisplayStore.listDisplay
                .filterByType(class: ItemListFilterAction.self)
            .do(onNext: { filterAction in
                if filterAction.filteringText.isEmpty {
                    self.view?.hideFilterCancelButton()
                } else {
                    self.view?.displayFilterCancelButton()
                }
            })

        let listDriver = self.createItemListDriver(
                itemListObservable: itemListObservable,
                filterTextObservable: filterTextObservable,
                itemSortObservable: itemSortObservable
        )

        self.view?.bind(items: listDriver)

        let itemSortTextDriver = itemSortObservable
                .asDriver(onErrorJustReturn: .alphabetically)
                .map { itemSortAction -> String in
                    switch itemSortAction {
                    case .alphabetically:
                        return Constant.string.aToZ
                    case .recentlyUsed:
                        return Constant.string.recent
                    }
                }

        self.view?.bind(sortingButtonTitle: itemSortTextDriver)

        self.itemListDisplayActionHandler.invoke(ItemListSortingAction.alphabetically)
        self.itemListDisplayActionHandler.invoke(ItemListFilterAction(filteringText: ""))
    }
}

extension ItemListPresenter {
    fileprivate func createItemListDriver(itemListObservable: Observable<[Item]>,
                                          filterTextObservable: Observable<ItemListFilterAction>,
                                          itemSortObservable: Observable<ItemListSortingAction>) -> Driver<[ItemSectionModel]> { // swiftlint:disable:this line_length
        return Observable.combineLatest(itemListObservable, filterTextObservable, itemSortObservable)
                .map { (latest: ([Item], ItemListFilterAction, ItemListSortingAction)) -> ItemListTextSort in
                    return ItemListTextSort(items: latest.0, text: latest.1.filteringText, sortingOption: latest.2)
                }
                .distinctUntilChanged()
                .map { (latest: ItemListTextSort) -> [Item] in
                    let baseDate = Date(timeIntervalSince1970: 0)

                    return self.filterItemsForText(latest.text, items: latest.items)
                            .sorted { lhs, rhs -> Bool in
                                switch latest.sortingOption {
                                case .alphabetically:
                                    return lhs.title ?? "" < rhs.title ?? ""
                                case .recentlyUsed:
                                    return lhs.lastUsedDate ?? baseDate > rhs.lastUsedDate ?? baseDate
                                }
                            }
                }
                .map { items -> [ItemSectionModel] in
                    return [ItemSectionModel(model: 0, items: self.configurationsFromItems(items))]
                }
                .asDriver(onErrorJustReturn: [])
    }

    fileprivate func configurationsFromItems(_ items: [Item]) -> [ItemListCellConfiguration] {
        let searchCell = [ItemListCellConfiguration.Search]

        let itemCells = items.map { item -> ItemListCellConfiguration in
            let titleText = item.title ?? ""
            let usernameEmpty = item.entry.username == "" || item.entry.username == nil
            let usernameText = usernameEmpty ? Constant.string.usernamePlaceholder : item.entry.username!

            return ItemListCellConfiguration.Item(title: titleText, username: usernameText, id: item.id)
        }

        return searchCell + itemCells
    }

    fileprivate func filterItemsForText(_ text: String, items: [Item]) -> [Item] {
        if text.isEmpty {
            return items
        }

        return items.filter { item -> Bool in
            return [item.entry.username, item.origins.first, item.title]
                    .compactMap {
                        $0?.localizedCaseInsensitiveContains(text) ?? false
                    }
                    .reduce(false) {
                        $0 || $1
                    }
        }
    }

    func dismissKeyboard() {
        view?.dismissKeyboard()
    }
}

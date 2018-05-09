/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Storage
import Shared

protocol ItemListViewProtocol: class, AlertControllerView {
    func bind(items: Driver<[ItemSectionModel]>)
    func bind(sortingButtonTitle: Driver<String>)
    func displayEmptyStateMessaging()
    func hideEmptyStateMessaging()
    func dismissKeyboard()
    func displayFilterCancelButton()
    func hideFilterCancelButton()
}

struct LoginListTextSort {
    let logins: [Login]
    let text: String
    let sortingOption: ItemListSortingAction
}

extension LoginListTextSort: Equatable {
    static func ==(lhs: LoginListTextSort, rhs: LoginListTextSort) -> Bool {
        return lhs.logins == rhs.logins &&
                lhs.text == rhs.text &&
                lhs.sortingOption == rhs.sortingOption
    }
}

class ItemListPresenter {
    private weak var view: ItemListViewProtocol?
    private var routeActionHandler: RouteActionHandler
    private var itemListDisplayActionHandler: ItemListDisplayActionHandler
    private var dataStoreActionHandler: DataStoreActionHandler
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

    lazy private(set) var refreshObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dataStoreActionHandler.invoke(.sync)
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
         dataStoreActionHandler: DataStoreActionHandler = DataStoreActionHandler.shared,
         dataStore: DataStore = DataStore.shared,
         itemListDisplayStore: ItemListDisplayStore = ItemListDisplayStore.shared) {
        self.view = view
        self.routeActionHandler = routeActionHandler
        self.itemListDisplayActionHandler = itemListDisplayActionHandler
        self.dataStoreActionHandler = dataStoreActionHandler
        self.dataStore = dataStore
        self.itemListDisplayStore = itemListDisplayStore
    }

    func onViewReady() {
        let itemListObservable = self.dataStore.list
                .asDriver(onErrorJustReturn: [])
                .do(onNext: { items in
                    if items.isEmpty {
                        self.view?.displayEmptyStateMessaging()
                    } else {
                        self.view?.hideEmptyStateMessaging()
                    }
                })
                .asObservable()
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
                loginListObservable: itemListObservable,
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
    fileprivate func createItemListDriver(loginListObservable: Observable<[Login]>,
                                          filterTextObservable: Observable<ItemListFilterAction>,
                                          itemSortObservable: Observable<ItemListSortingAction>) -> Driver<[ItemSectionModel]> { // swiftlint:disable:this line_length
        return Observable.combineLatest(loginListObservable, filterTextObservable, itemSortObservable)
                .map { (latest: ([Login], ItemListFilterAction, ItemListSortingAction)) -> LoginListTextSort in
                    return LoginListTextSort(logins: latest.0, text: latest.1.filteringText, sortingOption: latest.2)
                }
                .distinctUntilChanged()
                .map { (latest: LoginListTextSort) -> [Login] in
                    return self.filterItemsForText(latest.text, items: latest.logins)
                            .sorted { lhs, rhs -> Bool in
                                switch latest.sortingOption {
                                case .alphabetically:
                                    return lhs.hostname < rhs.hostname
                                case .recentlyUsed:
                                    return lhs.timeLastUsed > rhs.timeLastUsed
                                }
                            }
                }
                .map { items -> [ItemSectionModel] in
                    return [ItemSectionModel(model: 0, items: self.configurationsFromItems(items))]
                }
                .asDriver(onErrorJustReturn: [])
    }

    fileprivate func configurationsFromItems(_ items: [Login]) -> [LoginListCellConfiguration] {
        let searchCell = [LoginListCellConfiguration.Search]

        let loginCells = items.map { login -> LoginListCellConfiguration in
            let titleText = login.hostname
            let usernameEmpty = login.username == "" || login.username == nil
            let usernameText = usernameEmpty ? Constant.string.usernamePlaceholder : login.username!

            return LoginListCellConfiguration.Item(title: titleText, username: usernameText, guid: login.guid)
        }

        return searchCell + loginCells
    }

    fileprivate func filterItemsForText(_ text: String, items: [Login]) -> [Login] {
        if text.isEmpty {
            return items
        }

        return items.filter { item -> Bool in
            return [item.username, item.hostname]
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

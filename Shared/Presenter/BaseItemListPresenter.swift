/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Storage
import Shared

protocol BaseItemListViewProtocol: class {
    func bind(items: Driver<[ItemSectionModel]>)
    var sortingButtonHidden: AnyObserver<Bool>? { get }
    func dismissKeyboard()
}

struct LoginListTextSort {
    let logins: [Login]
    let text: String
    let sortingOption: Setting.ItemListSort
    let syncState: SyncState
    let storeState: LoginStoreState
}

extension LoginListTextSort: Equatable {
    static func ==(lhs: LoginListTextSort, rhs: LoginListTextSort) -> Bool {
        return lhs.logins == rhs.logins &&
            lhs.text == rhs.text &&
            lhs.sortingOption == rhs.sortingOption &&
            lhs.syncState == rhs.syncState
    }
}

class BaseItemListPresenter {
    internal weak var baseView: BaseItemListViewProtocol?
    internal let dispatcher: Dispatcher
    internal let dataStore: DataStore
    internal let itemListDisplayStore: ItemListDisplayStore
    internal let userDefaultStore: UserDefaultStore
    internal let disposeBag = DisposeBag()

    var itemSelectedObserver: AnyObserver<String?> {
        fatalError("not implemented!")
    }

    internal var learnMoreObserver: AnyObserver<Void> {
        fatalError("not implemented!")
    }

    internal var learnMoreNewEntriesObserver: AnyObserver<Void> {
        fatalError("not implemented!")
    }

    lazy private(set) var filterTextObserver: AnyObserver<String> = {
        return Binder(self) { target, filterText in
            target.dispatcher.dispatch(action: ItemListFilterAction(filteringText: filterText))
            target.dispatcher.dispatch(action: ItemListFilterEditAction(editing: true))
            }.asObserver()
    }()

    lazy private(set) var filterCancelObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.baseView?.dismissKeyboard()
            target.dispatcher.dispatch(action: ItemListFilterEditAction(editing: false))
            target.dispatcher.dispatch(action: ItemListFilterAction(filteringText: ""))
            }.asObserver()
    }()

    lazy private(set) var editEndedObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.baseView?.dismissKeyboard()
            target.dispatcher.dispatch(action: ItemListFilterEditAction(editing: false))
            }.asObserver()
    }()

    lazy fileprivate var emptyPlaceholderItems = [
        ItemSectionModel(model: 0, items: self.searchItem +
            [LoginListCellConfiguration.EmptyListPlaceholder(learnMoreObserver: self.learnMoreObserver)]
        )
    ]

    lazy fileprivate var noResultsPlaceholderItems = [
        ItemSectionModel(model: 0, items: self.searchItem +
            [LoginListCellConfiguration.NoResults(learnMoreObserver: self.learnMoreNewEntriesObserver)]
        )
    ]

    lazy internal var syncPlaceholderItems = [
        ItemSectionModel(model: 0, items: self.searchItem + [LoginListCellConfiguration.SyncListPlaceholder])
    ]

    lazy fileprivate var searchItem: [LoginListCellConfiguration] = {
        let enabledObservable = self.dataStore.list
            .map { !$0.isEmpty }

        let emptyTextObservable = self.itemListDisplayStore.listDisplay
            .filterByType(class: ItemListFilterAction.self)
            .map { $0.filteringText.isEmpty }

        let editingTextObservable = self.itemListDisplayStore.listDisplay
            .filterByType(class: ItemListFilterEditAction.self)
            .map { $0.editing }

        let cancelHiddenObservable = Observable.combineLatest(emptyTextObservable, editingTextObservable)
            .map { !(!$0.0 && $0.1) }
            .distinctUntilChanged()

        let externalTextChangeObservable = self.itemListDisplayStore.listDisplay
            .filterByType(class: ItemListFilterAction.self)
            .map { $0.filteringText }

        return [LoginListCellConfiguration.Search(
            enabled: enabledObservable,
            cancelHidden: cancelHiddenObservable,
            text: externalTextChangeObservable
            )]
    }()


    init(view: BaseItemListViewProtocol,
         dispatcher: Dispatcher = .shared,
         dataStore: DataStore = .shared,
         itemListDisplayStore: ItemListDisplayStore = .shared,
         userDefaultStore: UserDefaultStore = .shared) {
        self.baseView = view
        self.dispatcher = dispatcher
        self.dataStore = dataStore
        self.itemListDisplayStore = itemListDisplayStore
        self.userDefaultStore = userDefaultStore
    }

    func onViewReady() {
        let itemSortObservable = self.userDefaultStore.itemListSort

        let filterTextObservable = self.itemListDisplayStore.listDisplay
            .filterByType(class: ItemListFilterAction.self)

        let listDriver = self.createItemListDriver(
            loginListObservable: self.dataStore.list,
            filterTextObservable: filterTextObservable,
            itemSortObservable: itemSortObservable,
            syncStateObservable: self.dataStore.syncState,
            storageStateObservable: self.dataStore.storageState
        )

        self.baseView?.bind(items: listDriver)

        self.dispatcher.dispatch(action: ItemListFilterAction(filteringText: ""))
    }
}

extension BaseItemListPresenter {
    fileprivate func createItemListDriver(loginListObservable: Observable<[Login]>,
                                          filterTextObservable: Observable<ItemListFilterAction>,
                                          itemSortObservable: Observable<Setting.ItemListSort>,
                                          syncStateObservable: Observable<SyncState>,
                                          storageStateObservable: Observable<LoginStoreState>) -> Driver<[ItemSectionModel]> {
        // only run on a delay for UI purposes; keep tests from blocking
        let listThrottle = isRunningTest ? 0.0 : 1.0
        let stateThrottle = isRunningTest ? 0.0 : 2.0
        let throttledListObservable = loginListObservable
            .throttle(listThrottle, scheduler: ConcurrentMainScheduler.instance)
        let throttledSyncStateObservable = syncStateObservable
            .throttle(stateThrottle, scheduler: ConcurrentMainScheduler.instance)
        let throttledStorageStateObservable = storageStateObservable
            .throttle(stateThrottle, scheduler: ConcurrentMainScheduler.instance)

        return Observable.combineLatest(
            throttledListObservable,
            filterTextObservable,
            itemSortObservable,
            throttledSyncStateObservable,
            throttledStorageStateObservable
            )
            .map { (latest: ([Login], ItemListFilterAction, Setting.ItemListSort, SyncState, LoginStoreState)) -> LoginListTextSort in
                return LoginListTextSort(
                    logins: latest.0,
                    text: latest.1.filteringText,
                    sortingOption: latest.2,
                    syncState: latest.3,
                    storeState: latest.4
                )
            }
            .distinctUntilChanged()
            .map { (latest: LoginListTextSort) -> [ItemSectionModel] in
                if (latest.syncState == .Syncing || latest.syncState == .ReadyToSync) && latest.logins.isEmpty {
                    return self.syncPlaceholderItems
                }

                if latest.syncState == .Synced && latest.logins.isEmpty {
                    return self.emptyPlaceholderItems
                }

                let sortedFilteredItems = self.filterItemsForText(latest.text, items: latest.logins)
                    .sorted { lhs, rhs -> Bool in
                        switch latest.sortingOption {
                        case .alphabetically:
                            return lhs.hostname.titleFromHostname() < rhs.hostname.titleFromHostname()
                        case .recentlyUsed:
                            return lhs.timeLastUsed > rhs.timeLastUsed
                        }
                }

                if sortedFilteredItems.count == 0 {
                    return self.noResultsPlaceholderItems
                }

                return [ItemSectionModel(model: 0, items: self.configurationsFromItems(sortedFilteredItems))]
            }
            .asDriver(onErrorJustReturn: [])
    }

    fileprivate func configurationsFromItems(_ items: [Login]) -> [LoginListCellConfiguration] {
        let loginCells = items.map { login -> LoginListCellConfiguration in
            let titleText = login.hostname.titleFromHostname()
            let usernameEmpty = login.username == "" || login.username == nil
            let usernameText = usernameEmpty ? Constant.string.usernamePlaceholder : login.username!

            return LoginListCellConfiguration.Item(title: titleText, username: usernameText, guid: login.guid)
        }

        return self.searchItem + loginCells
    }

    fileprivate func filterItemsForText(_ text: String, items: [Login]) -> [Login] {
        if text.isEmpty {
            return items
        }

        return items.filter { item -> Bool in
            return [item.username, item.hostname.titleFromHostname()]
                .compactMap {
                    $0?.localizedCaseInsensitiveContains(text) ?? false
                }
                .reduce(false) {
                    $0 || $1
            }
        }
    }
}


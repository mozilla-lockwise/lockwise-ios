/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Logins

protocol BaseItemListViewProtocol: class {
    func bind(items: Driver<[ItemSectionModel]>)
    var sortingButtonHidden: AnyObserver<Bool>? { get }
    func dismissKeyboard()
    func setFilterEnabled(enabled: Bool)
}

struct LoginListTextSort {
    let logins: [LoginRecord]
    let text: String
    let sortingOption: Setting.ItemListSort
    let syncState: SyncState
    let storeState: LoginStoreState
    let detailItemId: String
}

extension LoginListTextSort: Equatable {
    static func ==(lhs: LoginListTextSort, rhs: LoginListTextSort) -> Bool {
        return lhs.logins == rhs.logins &&
            lhs.text == rhs.text &&
            lhs.sortingOption == rhs.sortingOption &&
            lhs.syncState == rhs.syncState &&
            lhs.detailItemId == rhs.detailItemId
    }
}

class BaseItemListPresenter {
    internal weak var baseView: BaseItemListViewProtocol?
    internal let dispatcher: Dispatcher
    internal let dataStore: DataStore
    internal let itemListDisplayStore: ItemListDisplayStore
    internal let userDefaultStore: UserDefaultStore
    internal let itemDetailStore: BaseItemDetailStore
    internal let sizeClassStore: SizeClassStore
    internal let disposeBag = DisposeBag()

    var itemSelectedObserver: AnyObserver<String?> {
        fatalError("not implemented!")
    }

    internal var learnMoreObserver: AnyObserver<Void>? {
        fatalError("not implemented!")
    }

    internal var learnMoreNewEntriesObserver: AnyObserver<Void>? {
        fatalError("not implemented!")
    }

    lazy private(set) var filterTextObserver: AnyObserver<String> = {
        return Binder(self) { target, filterText in
            target.dispatcher.dispatch(action: ItemListFilterAction(filteringText: filterText))
            target.dispatcher.dispatch(action: ItemListFilterEditAction(editing: true))
            }.asObserver()
    }()

    lazy private(set) var cancelObserver: AnyObserver<Void> = {
        return Binder(self) { target, filterText in
            target.dispatcher.dispatch(action: ItemListFilterAction(filteringText: ""))
            target.dispatcher.dispatch(action: ItemListFilterEditAction(editing: false))
        }.asObserver()
    }()

    lazy fileprivate var emptyPlaceholderItems = [
        ItemSectionModel(model: 0, items: [LoginListCellConfiguration.EmptyListPlaceholder(learnMoreObserver: self.learnMoreObserver)]
        )
    ]

    lazy fileprivate var noResultsPlaceholderItems = [
        ItemSectionModel(model: 0, items: [LoginListCellConfiguration.NoResults(learnMoreObserver: self.learnMoreNewEntriesObserver)]
        )
    ]

    lazy internal var syncPlaceholderItems = [
        ItemSectionModel(model: 0, items: [LoginListCellConfiguration.SyncListPlaceholder])
    ]

    var helpTextItems: [LoginListCellConfiguration] {
        return []
    }

    init(view: BaseItemListViewProtocol,
         dispatcher: Dispatcher = .shared,
         dataStore: DataStore = .shared,
         itemListDisplayStore: ItemListDisplayStore = .shared,
         userDefaultStore: UserDefaultStore = .shared,
         itemDetailStore: ItemDetailStore = .shared,
         sizeClassStore: SizeClassStore = .shared) {
        self.baseView = view
        self.dispatcher = dispatcher
        self.dataStore = dataStore
        self.itemListDisplayStore = itemListDisplayStore
        self.userDefaultStore = userDefaultStore
        self.itemDetailStore = itemDetailStore
        self.sizeClassStore = sizeClassStore
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
            storageStateObservable: self.dataStore.storageState,
            itemDetailIdObservable: self.itemDetailStore.itemDetailId,
            sidebarObservable: self.sizeClassStore.shouldDisplaySidebar
        )

        self.baseView?.bind(items: listDriver)

        self.dataStore.list
            .map { !$0.isEmpty }
            .subscribe { (evt) in
                self.baseView?.setFilterEnabled(enabled: evt.element ?? false)
            }
            .disposed(by: self.disposeBag)

        self.dispatcher.dispatch(action: ItemListFilterAction(filteringText: ""))
    }
}

extension BaseItemListPresenter {
    fileprivate func createItemListDriver(loginListObservable: Observable<[LoginRecord]>,
                                          filterTextObservable: Observable<ItemListFilterAction>,
                                          itemSortObservable: Observable<Setting.ItemListSort>,
                                          syncStateObservable: Observable<SyncState>,
                                          storageStateObservable: Observable<LoginStoreState>,
                                          itemDetailIdObservable: Observable<String>,
                                          sidebarObservable: Observable<Bool>) -> Driver<[ItemSectionModel]> {
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
            throttledStorageStateObservable,
            itemDetailIdObservable,
            sidebarObservable
            )
            .map { (latest: ([LoginRecord], ItemListFilterAction, Setting.ItemListSort, SyncState, LoginStoreState, String, Bool)) -> LoginListTextSort in
                return LoginListTextSort(
                    logins: latest.0,
                    text: latest.1.filteringText,
                    sortingOption: latest.2,
                    syncState: latest.3,
                    storeState: latest.4,
                    detailItemId: latest.6 ? latest.5 : "" // only pass along the detailItemId if we are showing the sidebar
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

                return [ItemSectionModel(model: 0, items: self.configurationsFromItems(sortedFilteredItems, detailItemId: latest.detailItemId))]
            }
            .asDriver(onErrorJustReturn: [])
    }

    fileprivate func configurationsFromItems(_ items: [LoginRecord], detailItemId: String) -> [LoginListCellConfiguration] {
        let loginCells = items.map { login -> LoginListCellConfiguration in
            let titleText = login.hostname.titleFromHostname()
            let usernameEmpty = login.username == "" || login.username == nil
            let usernameText = usernameEmpty ? Constant.string.usernamePlaceholder : login.username!

            return LoginListCellConfiguration.Item(
                title: titleText,
                username: usernameText,
                guid: login.id,
                highlight: login.id == detailItemId)
        }

        return self.helpTextItems + loginCells
    }

    fileprivate func filterItemsForText(_ text: String, items: [LoginRecord]) -> [LoginRecord] {
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


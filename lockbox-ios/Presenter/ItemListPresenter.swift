/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Storage
import Shared

protocol ItemListViewProtocol: class, AlertControllerView, SpinnerAlertView {
    func bind(items: Driver<[ItemSectionModel]>)
    func bind(sortingButtonTitle: Driver<String>)
    var sortingButtonEnabled: AnyObserver<Bool>? { get }
    var tableViewScrollEnabled: AnyObserver<Bool> { get }
    func dismissKeyboard()
    var pullToRefreshActive: AnyObserver<Bool>? { get }
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

struct SyncStateManual {
    let syncState: SyncState
    let manualSync: Bool
}

class ItemListPresenter {
    private weak var view: ItemListViewProtocol?
    private let dispatcher: Dispatcher
    private let dataStore: DataStore
    private let itemListDisplayStore: ItemListDisplayStore
    private let userDefaultStore: UserDefaultStore
    private let disposeBag = DisposeBag()

    lazy private(set) var itemSelectedObserver: AnyObserver<String?> = {
        return Binder(self) { target, itemId in
            guard let id = itemId else {
                return
            }

            if let view = target.view {
                view.dismissKeyboard()
            }

            target.dispatcher.dispatch(action: MainRouteAction.detail(itemId: id))
        }.asObserver()
    }()

    lazy private(set) var onSettingsTapped: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: SettingRouteAction.list)
        }.asObserver()
    }()

    lazy private(set) var filterTextObserver: AnyObserver<String> = {
        return Binder(self) { target, filterText in
            target.dispatcher.dispatch(action: ItemListFilterAction(filteringText: filterText))
            target.dispatcher.dispatch(action: ItemListFilterEditAction(editing: true))
        }.asObserver()
    }()

    lazy private(set) var filterCancelObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.view?.dismissKeyboard()
            target.dispatcher.dispatch(action: ItemListFilterEditAction(editing: false))
            target.dispatcher.dispatch(action: ItemListFilterAction(filteringText: ""))
        }.asObserver()
    }()

    lazy private(set) var editEndedObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.view?.dismissKeyboard()
            target.dispatcher.dispatch(action: ItemListFilterEditAction(editing: false))
        }.asObserver()
    }()

    lazy private(set) var refreshObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: PullToRefreshAction(refreshing: true))
            target.dispatcher.dispatch(action: DataStoreAction.sync)
        }.asObserver()
    }()

    lazy private(set) var sortingButtonObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            self.userDefaultStore.itemListSort
                .take(1)
                .subscribe(onNext: { evt in
                let latest = evt
                target.view?.displayAlertController(buttons: [
                    AlertActionButtonConfiguration(
                            title: Constant.string.alphabetically,
                            tapObserver: target.alphabeticSortObserver,
                            style: .default,
                            checked: latest == Setting.ItemListSort.alphabetically),
                    AlertActionButtonConfiguration(
                            title: Constant.string.recentlyUsed,
                            tapObserver: target.recentlyUsedSortObserver,
                            style: .default,
                            checked: latest == Setting.ItemListSort.recentlyUsed),
                    AlertActionButtonConfiguration(
                            title: Constant.string.cancel,
                            tapObserver: nil,
                            style: .cancel)],
                        title: Constant.string.sortEntries,
                        message: nil,
                        style: .actionSheet)
            }).disposed(by: self.disposeBag)
        }.asObserver()
    }()

    lazy private var alphabeticSortObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: SettingAction.itemListSort(sort: Setting.ItemListSort.alphabetically))
        }.asObserver()
    }()

    lazy private var recentlyUsedSortObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: SettingAction.itemListSort(sort: Setting.ItemListSort.recentlyUsed))
        }.asObserver()
    }()

    lazy private var learnMoreObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: ExternalWebsiteRouteAction(
                    urlString: Constant.app.enableSyncFAQ,
                    title: Constant.string.faq,
                    returnRoute: MainRouteAction.list))
        }.asObserver()
    }()

    lazy private var learnMoreNewEntriesObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: ExternalWebsiteRouteAction(
                urlString: Constant.app.createNewEntriesFAQ,
                title: Constant.string.faq,
                returnRoute: MainRouteAction.list))
        }.asObserver()
    }()

    lazy private var emptyPlaceholderItems = [
        ItemSectionModel(model: 0, items: self.searchItem +
                [LoginListCellConfiguration.EmptyListPlaceholder(learnMoreObserver: self.learnMoreObserver)]
        )
    ]

    lazy private var noResultsPlaceholderItems = [
        ItemSectionModel(model: 0, items: self.searchItem +
                [LoginListCellConfiguration.NoResults(learnMoreObserver: self.learnMoreNewEntriesObserver)]
        )
    ]

    lazy private var syncPlaceholderItems = [
        ItemSectionModel(model: 0, items: self.searchItem + [LoginListCellConfiguration.SyncListPlaceholder])
    ]

    lazy private var searchItem: [LoginListCellConfiguration] = {
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

    init(view: ItemListViewProtocol,
         dispatcher: Dispatcher = .shared,
         dataStore: DataStore = DataStore.shared,
         itemListDisplayStore: ItemListDisplayStore = ItemListDisplayStore.shared,
         userDefaultStore: UserDefaultStore = .shared) {
        self.view = view
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

        self.view?.bind(items: listDriver)
        self.setupSpinnerDisplay()

        guard let view = self.view,
              let sortButtonObserver = view.sortingButtonEnabled,
              let pullToRefreshActiveObserver = view.pullToRefreshActive else { return }

        self.setupPullToRefresh(pullToRefreshActiveObserver)
        self.setupButtonBehavior(
                view: view,
                itemSortObservable: itemSortObservable,
                sortButtonObserver: sortButtonObserver
        )

        self.dispatcher.dispatch(action: ItemListFilterAction(filteringText: ""))
        self.dispatcher.dispatch(action: PullToRefreshAction(refreshing: false))
    }
}

extension ItemListPresenter {
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

extension ItemListPresenter {
    fileprivate func setupSpinnerDisplay() {
        // when this observable emits an event, the spinner gets dismissed
        let hideSpinnerObservable = self.dataStore.syncState
                .filter { $0 == SyncState.Synced }
                .map { _ in return () }
                .asDriver(onErrorJustReturn: ())

        let isManualRefreshObservable = self.itemListDisplayStore.listDisplay
                .filterByType(class: PullToRefreshAction.self)

        Observable.combineLatest(self.dataStore.syncState, isManualRefreshObservable)
                .map { SyncStateManual(syncState: $0.0, manualSync: $0.1.refreshing) }
                .asDriver(onErrorJustReturn: SyncStateManual(syncState: .Synced, manualSync: false))
                .throttle(2.0)
                .drive(onNext: { latest in
                    if (latest.syncState == SyncState.Syncing || latest.syncState == SyncState.ReadyToSync)
                               && !latest.manualSync {
                        self.view?.displaySpinner(hideSpinnerObservable, bag: self.disposeBag, message: Constant.string.syncingYourEntries, completionMessage: Constant.string.doneSyncingYourEntries)
                    }
                })
                .disposed(by: self.disposeBag)
    }

    fileprivate func setupPullToRefresh(_ pullToRefreshActive: AnyObserver<Swift.Bool>) {
        let syncingObserver = self.dataStore.syncState
                .map { $0 == .Syncing }

        let isManualRefreshObservable = self.itemListDisplayStore.listDisplay
                .filterByType(class: PullToRefreshAction.self)

        Observable.combineLatest(syncingObserver, isManualRefreshObservable)
                .map { $0.0 && $0.1.refreshing }
                .bind(to: pullToRefreshActive)
                .disposed(by: self.disposeBag)

        self.dataStore.syncState
                .filter { $0 == .Synced }
                .subscribe(onNext: { _ in
                    self.dispatcher.dispatch(action: PullToRefreshAction(refreshing: false))
                })
                .disposed(by: self.disposeBag)
    }

    fileprivate func setupButtonBehavior(
            view: ItemListViewProtocol,
            itemSortObservable: Observable<Setting.ItemListSort>,
            sortButtonObserver: AnyObserver<Bool>) {
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

        view.bind(sortingButtonTitle: itemSortTextDriver)

        let loginListEmptyObservable = self.dataStore.list.map { $0.isEmpty }
        let isSyncingObservable = self.dataStore.syncState.map { $0 == .Syncing }
        let enableObservable = isSyncingObservable.withLatestFrom(loginListEmptyObservable) { (isSyncing, isListEmpty) in
          return !(isSyncing && isListEmpty)
        }

        enableObservable.bind(to: sortButtonObserver).disposed(by: self.disposeBag)
        enableObservable.bind(to: view.tableViewScrollEnabled).disposed(by: self.disposeBag)
    }
}

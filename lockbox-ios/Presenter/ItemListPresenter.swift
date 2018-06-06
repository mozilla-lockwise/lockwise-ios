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
    var settingButtonEnabled: AnyObserver<Bool>? { get }
    var tableViewScrollEnabled: AnyObserver<Bool> { get }
    func dismissKeyboard()
    var pullToRefreshActive: AnyObserver<Bool>? { get }
}

struct LoginListTextSort {
    let logins: [Login]
    let text: String
    let sortingOption: ItemListSortingAction
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
            target.itemListDisplayActionHandler.invoke(ItemListFilterEditAction(editing: true))
        }.asObserver()
    }()

    lazy private(set) var filterCancelObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.view?.dismissKeyboard()
            target.itemListDisplayActionHandler.invoke(ItemListFilterEditAction(editing: false))
            target.itemListDisplayActionHandler.invoke(ItemListFilterAction(filteringText: ""))
        }.asObserver()
    }()

    lazy private(set) var editEndedObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.view?.dismissKeyboard()
            target.itemListDisplayActionHandler.invoke(ItemListFilterEditAction(editing: false))
        }.asObserver()
    }()

    lazy private(set) var refreshObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.itemListDisplayActionHandler.invoke(PullToRefreshAction(refreshing: true))
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

    lazy private var learnMoreObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(ExternalWebsiteRouteAction(
                    urlString: Constant.app.enableSyncFAQ,
                    title: Constant.string.faq,
                    returnRoute: MainRouteAction.list))
        }.asObserver()
    }()

    lazy private var emptyPlaceholderItems = [
        ItemSectionModel(model: 0, items: self.searchItem +
                [LoginListCellConfiguration.EmptyListPlaceholder(learnMoreObserver: self.learnMoreObserver)]
        )
    ]

    lazy private var preparingPlaceholderItems = [
        ItemSectionModel(model: 0, items: self.searchItem +
            [LoginListCellConfiguration.PreparingPlaceholder]
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

    func onViewReady() { // swiftlint:disable:this function_body_length
        let itemSortObservable = self.itemListDisplayStore.listDisplay
                .filterByType(class: ItemListSortingAction.self)

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

        guard let view = self.view,
              let sortButtonObserver = view.sortingButtonEnabled,
              let settingButtonObserver = view.settingButtonEnabled else {
            return
         }

        let syncingObserver = self.dataStore.syncState
                .map {  $0 == .Syncing }

        let isManualRefreshObservable = self.itemListDisplayStore.listDisplay
                .filterByType(class: PullToRefreshAction.self)

        if let pullToRefreshActive = view.pullToRefreshActive {
            Observable.combineLatest(syncingObserver, isManualRefreshObservable)
                    .map { $0.0 && $0.1.refreshing }
                    .bind(to: pullToRefreshActive)
                    .disposed(by: self.disposeBag)
        }

        self.dataStore.syncState
                .filter { $0 == .Synced }
                .subscribe(onNext: { _ in
                    self.itemListDisplayActionHandler.invoke(PullToRefreshAction(refreshing: false))
                })
                .disposed(by: self.disposeBag)

        let enableObservable = self.dataStore.list.map { !$0.isEmpty }

        enableObservable.bind(to: sortButtonObserver).disposed(by: self.disposeBag)
        enableObservable.bind(to: view.tableViewScrollEnabled).disposed(by: self.disposeBag)

        let preparingObservable = self.dataStore.storageState.map { $0 != LoginStoreState.Preparing }
        preparingObservable.bind(to: settingButtonObserver).disposed(by: self.disposeBag)

        // when this observable emits an event, the spinner gets dismissed
        let hideSpinnerObservable = self.dataStore.syncState
                .filter { $0 == SyncState.Synced }
                .map { _ in return () }
                .asDriver(onErrorJustReturn: ())

        Observable.combineLatest(self.dataStore.syncState, isManualRefreshObservable)
                .debug()
                .asDriver(onErrorJustReturn: (SyncState.Synced, PullToRefreshAction(refreshing: false)))
                .drive(onNext: { latest in
                    if (latest.0 == SyncState.Syncing || latest.0 == SyncState.ReadyToSync) && !latest.1.refreshing {
                        self.view?.displaySpinner(hideSpinnerObservable, bag: self.disposeBag)
                    }
                })
                .disposed(by: self.disposeBag)

        self.itemListDisplayActionHandler.invoke(ItemListSortingAction.alphabetically)
        self.itemListDisplayActionHandler.invoke(ItemListFilterAction(filteringText: ""))
        self.itemListDisplayActionHandler.invoke(PullToRefreshAction(refreshing: false))
    }
}

extension ItemListPresenter {
    fileprivate func createItemListDriver(loginListObservable: Observable<[Login]>,
                                          filterTextObservable: Observable<ItemListFilterAction>,
                                          itemSortObservable: Observable<ItemListSortingAction>,
                                          syncStateObservable: Observable<SyncState>,
                                          storageStateObservable: Observable<LoginStoreState>) -> Driver<[ItemSectionModel]> { // swiftlint:disable:this line_length
        return Observable.combineLatest(
                        loginListObservable,
                        filterTextObservable,
                        itemSortObservable,
                        syncStateObservable,
                        storageStateObservable
                )
            .map { (latest: ([Login], ItemListFilterAction, ItemListSortingAction, SyncState, LoginStoreState)) -> LoginListTextSort in // swiftlint:disable:this line_length
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

                    if latest.storeState == .Preparing {
                        return self.preparingPlaceholderItems
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

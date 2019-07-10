/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import MozillaAppServices

protocol ItemListViewProtocol: AlertControllerView, StatusAlertView, SpinnerAlertView, BaseItemListViewProtocol {
    func bind(sortingButtonTitle: Driver<String>)
    func bind(scrollAction: Driver<ScrollAction>)
    func showDeletedStatusAlert(message: String)
    var sortingButtonEnabled: AnyObserver<Bool>? { get }
    var tableViewScrollEnabled: AnyObserver<Bool> { get }
    var pullToRefreshActive: AnyObserver<Bool>? { get }
    var onSettingsButtonPressed: ControlEvent<Void>? { get }
    var onSortingButtonPressed: ControlEvent<Void>? { get }
    var itemDeleted: Observable<String> { get }
    var sortButton: UIBarButtonItem? { get }
}

struct SyncStateManual {
    let syncState: SyncState
    let manualSync: Bool
}

class ItemListPresenter: BaseItemListPresenter {
    weak var view: ItemListViewProtocol? {
        return self.baseView as? ItemListViewProtocol
    }

    lazy private(set) var listSortedObserver: AnyObserver<Setting.ItemListSort> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: ScrollAction.toTop)
        }.asObserver()
    }()

    override var itemSelectedObserver: AnyObserver<String?> {
        return Binder(self) { target, itemId in
            guard let id = itemId else {
                return
            }

            if let view = target.view {
                view.dismissKeyboard()
            }

            target.dispatcher.dispatch(action: MainRouteAction.detail(itemId: id))
        }.asObserver()
    }

    lazy private(set) var refreshObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: PullToRefreshAction(refreshing: true))
            target.dispatcher.dispatch(action: DataStoreAction.sync)
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

    override var learnMoreObserver: AnyObserver<Void>? {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: ExternalWebsiteRouteAction(
                    urlString: Constant.app.enableSyncFAQ,
                    title: Constant.string.faq,
                    returnRoute: MainRouteAction.list))
        }.asObserver()
    }

    override var learnMoreNewEntriesObserver: AnyObserver<Void>? {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: ExternalWebsiteRouteAction(
                urlString: Constant.app.createNewEntriesFAQ,
                title: Constant.string.faq,
                returnRoute: MainRouteAction.list))
        }.asObserver()
    }

    init(view: ItemListViewProtocol,
         dispatcher: Dispatcher = .shared,
         dataStore: DataStore = DataStore.shared,
         itemListDisplayStore: ItemListDisplayStore = ItemListDisplayStore.shared,
         userDefaultStore: UserDefaultStore = .shared,
         itemDetailStore: ItemDetailStore = .shared,
         networkStore: NetworkStore = .shared,
         sizeClassStore: SizeClassStore = .shared) {

        super.init(view: view,
                   dispatcher: dispatcher,
                   dataStore: dataStore,
                   itemListDisplayStore: itemListDisplayStore,
                   userDefaultStore: userDefaultStore,
                   itemDetailStore: itemDetailStore,
                   networkStore: networkStore,
                   sizeClassStore: sizeClassStore)
    }

    override func onViewReady() {
        super.onViewReady()
        self.setupSpinnerDisplay()

        let itemSortObservable = self.userDefaultStore.itemListSort
        itemSortObservable.bind(to: self.listSortedObserver).disposed(by: self.disposeBag)

        guard let view = self.view,
              let sortButtonObserver = view.sortingButtonEnabled,
              let pullToRefreshActiveObserver = view.pullToRefreshActive else { return }

        let scrollActionDriver = self.dispatcher.register
            .filterByType(class: ScrollAction.self)
            .asDriver(onErrorJustReturn: ScrollAction.toTop)
        view.bind(scrollAction: scrollActionDriver)

        self.setupButtonBehavior(
                view: view,
                itemSortObservable: itemSortObservable,
                sortButtonObserver: sortButtonObserver
        )

        self.setupPullToRefresh(pullToRefreshActiveObserver)
        self.dispatcher.dispatch(action: PullToRefreshAction(refreshing: false))

        if let onSettingsButtonPressed = self.view?.onSettingsButtonPressed {
            onSettingsButtonPressed.subscribe { _ in
                self.dispatcher.dispatch(action: SettingRouteAction.list)
                }.disposed(by: disposeBag)
        }

        if let onSortingButtonPressed = self.view?.onSortingButtonPressed {
            onSortingButtonPressed.subscribe { _ in
                self.userDefaultStore.itemListSort
                    .take(1)
                    .subscribe(onNext: { [weak self] evt in
                        guard let strongSelf = self else { return }
                        let latest = evt
                        view.displayAlertController(
                            buttons: [
                                AlertActionButtonConfiguration(
                                    title: Constant.string.alphabetically,
                                    tapObserver: strongSelf.alphabeticSortObserver,
                                    style: .default,
                                    checked: latest == Setting.ItemListSort.alphabetically),
                                AlertActionButtonConfiguration(
                                    title: Constant.string.recentlyUsed,
                                    tapObserver: strongSelf.recentlyUsedSortObserver,
                                    style: .default,
                                    checked: latest == Setting.ItemListSort.recentlyUsed),
                                AlertActionButtonConfiguration(
                                    title: Constant.string.cancel,
                                    tapObserver: nil,
                                    style: .cancel)
                            ],
                            title: Constant.string.sortEntries,
                            message: nil,
                            style: .actionSheet,
                            barButtonItem: self?.view?.sortButton)
                    })
                    .disposed(by: self.disposeBag)
            }
            .disposed(by: self.disposeBag)

        }

        if let itemDeleted = self.view?.itemDeleted {
            itemDeleted.subscribe(onNext: { (id) in
                self.view?.displayAlertController(
                    buttons: [
                        AlertActionButtonConfiguration(
                            title: Constant.string.cancel,
                            tapObserver: nil,
                            style: .cancel
                        ),
                        AlertActionButtonConfiguration(
                            title: Constant.string.delete,
                            tapObserver: self.getDeletedItemObserver(id: id),
                            style: .destructive)
                    ],
                    title: Constant.string.confirmDeleteLoginDialogTitle,
                    message: String(format: Constant.string.confirmDeleteLoginDialogMessage,
                                    Constant.string.productNameShort),
                    style: .alert,
                    barButtonItem: nil)
            })
            .disposed(by: self.disposeBag)
        }

        self.itemListDisplayStore.listDisplay
            .filterByType(class: ItemDeletedAction.self)
            .subscribe(onNext: { (action) in
                self.view?.showDeletedStatusAlert(message:
                    String(format: Constant.string.deletedStatusAlert, action.name))
            })
            .disposed(by: self.disposeBag)
    }

    private func getDeletedItemObserver(id: String) -> AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: DataStoreAction.delete(id: id))
            target.dispatcher.dispatch(action: MainRouteAction.list)
        }.asObserver()
    }
}

extension ItemListPresenter {
    fileprivate func setupSpinnerDisplay() {
        // when this observable emits an event, the spinner gets dismissed
        let hideSpinnerObservable = self.dataStore.syncState
                .filter { $0 == SyncState.Synced || $0 == SyncState.TimedOut }
                .map { _ in return () }
                .asDriver(onErrorJustReturn: ())

        let isManualRefreshObservable = self.itemListDisplayStore.listDisplay
                .filterByType(class: PullToRefreshAction.self)

        Observable.combineLatest(self.dataStore.syncState, isManualRefreshObservable)
                .map { SyncStateManual(syncState: $0.0, manualSync: $0.1.refreshing) }
                .asDriver(onErrorJustReturn: SyncStateManual(syncState: .Synced, manualSync: false))
                .throttle(2.0)
                .drive(onNext: { latest in
                    if latest.syncState == .Syncing(supressNotification: false) && !latest.manualSync {
                        self.view?.displaySpinner(hideSpinnerObservable,
                                                  bag: self.disposeBag,
                                                  message: Constant.string.syncingYourEntries,
                                                  completionMessage: Constant.string.doneSyncingYourEntries)
                    }
                })
                .disposed(by: self.disposeBag)

        self.dataStore.syncState
                .filter { $0 == SyncState.TimedOut }
                .map { _ in () }
                .asDriver(onErrorJustReturn: () )
                .drive(onNext: { _ in
                    self.view?.displayTemporaryAlert(Constant.string.syncTimedOut, timeout: 5, icon: nil)
                })
                .disposed(by: self.disposeBag)
    }
}

extension ItemListPresenter {
    fileprivate func setupPullToRefresh(_ pullToRefreshActive: AnyObserver<Swift.Bool>) {
        let syncingObserver = self.dataStore.syncState
                .map { $0.isSyncing() }

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
        let isSyncingObservable = self.dataStore.syncState.map { $0.isSyncing() }
        let enableObservable = isSyncingObservable.withLatestFrom(loginListEmptyObservable) { (isSyncing, isListEmpty) in
          return !(isSyncing && isListEmpty)
        }

        enableObservable.bind(to: sortButtonObserver).disposed(by: self.disposeBag)
        enableObservable.bind(to: view.tableViewScrollEnabled).disposed(by: self.disposeBag)
    }
}

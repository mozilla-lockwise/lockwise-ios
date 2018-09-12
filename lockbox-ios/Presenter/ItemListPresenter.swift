/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import Storage
import Shared

protocol ItemListViewProtocol: AlertControllerView, SpinnerAlertView, BaseItemListViewProtocol {
    func bind(sortingButtonTitle: Driver<String>)
    var sortingButtonEnabled: AnyObserver<Bool>? { get }
    var tableViewScrollEnabled: AnyObserver<Bool> { get }
    var pullToRefreshActive: AnyObserver<Bool>? { get }
}

struct SyncStateManual {
    let syncState: SyncState
    let manualSync: Bool
}

class ItemListPresenter: BaseItemListPresenter {
    weak var view: ItemListViewProtocol? {
        return self.baseView as? ItemListViewProtocol
    }

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

    lazy private(set) var onSettingsTapped: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: SettingRouteAction.list)
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

    override var learnMoreObserver: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: ExternalWebsiteRouteAction(
                    urlString: Constant.app.enableSyncFAQ,
                    title: Constant.string.faq,
                    returnRoute: MainRouteAction.list))
        }.asObserver()
    }

    override var learnMoreNewEntriesObserver: AnyObserver<Void> {
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
         userDefaultStore: UserDefaultStore = .shared) {

        super.init(view: view,
                   dispatcher: dispatcher,
                   dataStore: dataStore,
                   itemListDisplayStore: itemListDisplayStore,
                   userDefaultStore: userDefaultStore)
    }

    override func onViewReady() {
        super.onViewReady()
        self.setupSpinnerDisplay()

        let itemSortObservable = self.userDefaultStore.itemListSort

        guard let view = self.view,
              let sortButtonObserver = view.sortingButtonEnabled,
              let pullToRefreshActiveObserver = view.pullToRefreshActive else { return }

        self.setupButtonBehavior(
                view: view,
                itemSortObservable: itemSortObservable,
                sortButtonObserver: sortButtonObserver
        )

        self.setupPullToRefresh(pullToRefreshActiveObserver)
        self.dispatcher.dispatch(action: PullToRefreshAction(refreshing: false))
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
}

extension ItemListPresenter {
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

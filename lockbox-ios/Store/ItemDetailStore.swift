/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class ItemDetailStore: BaseItemDetailStore {
    public static let shared = ItemDetailStore()

    private var dataStore: DataStore
    private var sizeClassStore: SizeClassStore

    private var _itemDetailDisplay = ReplaySubject<ItemDetailDisplayAction>.create(bufferSize: 1)

    lazy private(set) var itemDetailDisplay: Driver<ItemDetailDisplayAction> = {
        return self._itemDetailDisplay.asDriver(onErrorJustReturn: .togglePassword(displayed: false))
    }()

    // RootPresenter needs a synchronous way to find out if the detail screen has a login or not
    private(set) var itemDetailHasId = false

    init(dispatcher: Dispatcher = Dispatcher.shared,
         dataStore: DataStore = DataStore.shared,
         sizeClassStore: SizeClassStore = SizeClassStore.shared) {
        self.dataStore = dataStore
        self.sizeClassStore = sizeClassStore

        super.init(dispatcher: dispatcher)

        self.dispatcher.register
            .filterByType(class: ItemDetailDisplayAction.self)
            .bind(to: self._itemDetailDisplay)
            .disposed(by: self.disposeBag)

        self.dispatcher.register
            .filterByType(class: MainRouteAction.self)
            .subscribe(onNext: { (route) in
                switch route {
                case .detail(let itemId):
                    self._itemDetailId.onNext(itemId)
                case .list:
                    break
                }
            }).disposed(by: self.disposeBag)

        self.itemDetailId
            .subscribe(onNext: { itemId in
                self.itemDetailHasId = itemId != ""
            })
            .disposed(by: self.disposeBag)

        // If the splitview is being show
        // then after sync, select one item from the datastore to show
        Observable.combineLatest(sizeClassStore.shouldDisplaySidebar, self.dataStore.syncState)
            .subscribe(onNext: { (displayingSidebar, syncState) in
                if displayingSidebar && syncState == SyncState.Synced {
                    self._itemDetailId
                        .take(1)
                        .ifEmpty(switchTo: Observable.just(""))
                        .subscribe(onNext: { (itemId) in
                            if itemId == "" {
                                self.showFirstLogin()
                            }
                        })
                        .disposed(by: self.disposeBag)
                }
            })
            .disposed(by: self.disposeBag)
    }

    private func showFirstLogin() {
        self.dataStore.list
            .take(1)
            .subscribe(onNext: { (logins) in
                if let firstLogin = logins.first {
                    DispatchQueue.main.async {
                        self._itemDetailId.onNext(firstLogin.guid)
                    }
                }
            })
            .disposed(by: self.disposeBag)
    }
}

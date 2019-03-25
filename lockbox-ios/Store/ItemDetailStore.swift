/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import Logins

class ItemDetailStore: BaseItemDetailStore {
    public static let shared = ItemDetailStore()

    private var dataStore: DataStore
    private var sizeClassStore: SizeClassStore
    private var userDefaultStore: UserDefaultStore

    private var _itemDetailDisplay = ReplaySubject<ItemDetailDisplayAction>.create(bufferSize: 1)

    lazy private(set) var itemDetailDisplay: Driver<ItemDetailDisplayAction> = {
        return self._itemDetailDisplay.asDriver(onErrorJustReturn: .togglePassword(displayed: false))
    }()

    // RootPresenter needs a synchronous way to find out if the detail screen has a login or not
    private(set) var itemDetailHasId = false

    init(dispatcher: Dispatcher = Dispatcher.shared,
         dataStore: DataStore = DataStore.shared,
         sizeClassStore: SizeClassStore = SizeClassStore.shared,
         userDefaultStore: UserDefaultStore = UserDefaultStore.shared) {
        self.dataStore = dataStore
        self.sizeClassStore = sizeClassStore
        self.userDefaultStore = userDefaultStore

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
        Observable.combineLatest(sizeClassStore.shouldDisplaySidebar,
                                 self.dataStore.list,
                                 self.itemDetailId,
                                 self.userDefaultStore.itemListSort)
            .filter({ (displayingSidebar, list, itemId, sort) -> Bool in
                return displayingSidebar && list.count > 0 && itemId == ""
            })
            .subscribe(onNext: { (displayingSidebar, list, itemId, sort) in
                let sortedList = list.sorted { lhs, rhs -> Bool in
                    switch sort {
                    case .alphabetically:
                        return lhs.hostname.titleFromHostname() < rhs.hostname.titleFromHostname()
                    case .recentlyUsed:
                        return lhs.timeLastUsed > rhs.timeLastUsed
                    }
                }

                self.showFirstLogin(sortedList.first)
            })
            .disposed(by: self.disposeBag)
    }

    private func showFirstLogin(_ login: LoginRecord?) {
        if let login = login {
            runOnMainThread {
                self._itemDetailId.onNext(login.id)
            }
        }
    }

    private func runOnMainThread(completion: @escaping () -> Void) {
        if Thread.isMainThread {
            completion()
        } else {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

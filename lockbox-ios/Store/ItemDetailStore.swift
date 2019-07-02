/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MozillaAppServices

class ItemDetailStore: BaseItemDetailStore {
    public static let shared = ItemDetailStore()

    private var dataStore: DataStore
    private var sizeClassStore: SizeClassStore
    private var lifecycleStore: LifecycleStore
    private var userDefaultStore: UserDefaultStore
    private var routeStore: RouteStore
    private var itemListDisplayStore: ItemListDisplayStore

    private var _passwordRevealed = BehaviorRelay<Bool>(value: false)

    lazy private(set) var passwordRevealed: Driver<Bool> = {
        return self._passwordRevealed.asDriver(onErrorJustReturn: false)
    }()

    // RootPresenter needs a synchronous way to find out if the detail screen has a login or not
    var itemDetailHasId: Bool {
        return self._itemDetailId.value != ""
    }

    init(
            dispatcher: Dispatcher = .shared,
            dataStore: DataStore = .shared,
            sizeClassStore: SizeClassStore = .shared,
            lifecycleStore: LifecycleStore = .shared,
            userDefaultStore: UserDefaultStore = .shared,
            routeStore: RouteStore = .shared,
            itemListDisplayStore: ItemListDisplayStore = .shared
    ) {
        self.dataStore = dataStore
        self.sizeClassStore = sizeClassStore
        self.lifecycleStore = lifecycleStore
        self.userDefaultStore = userDefaultStore
        self.routeStore = routeStore
        self.itemListDisplayStore = itemListDisplayStore

        super.init(dispatcher: dispatcher)

        self.dispatcher.register
                .filterByType(class: ItemDetailDisplayAction.self)
                .map { action -> Bool? in
                    if case let .togglePassword(displayed) = action {
                        return displayed
                    } else {
                        return nil
                    }
                }
                .filterNil()
                .bind(to: self._passwordRevealed)
                .disposed(by: self.disposeBag)

        self.lifecycleStore.lifecycleEvents
                .filter { $0 == .background }
                .map { _ in false }
                .bind(to: self._passwordRevealed)
                .disposed(by: self.disposeBag)

        self.routeStore.onRoute
                .filterByType(class: MainRouteAction.self)
                .map { route -> String? in
                    switch route {
                    case .detail(let itemId):
                        return itemId
                    case .list:
                        return nil
                    }
                }
                .filterNil()
                .bind(to: self._itemDetailId)
                .disposed(by: self.disposeBag)

        self.itemListDisplayStore.listDisplay
            .filterByType(class: ItemDeletedAction.self)
            .filter { self._itemDetailId.value == $0.id }
            .subscribe(onNext: { (action) in
                self._itemDetailId.accept("")
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
                self._itemDetailId.accept(login.id)
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

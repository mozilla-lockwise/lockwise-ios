/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import MozillaAppServices
import RxOptional

class ItemDetailStore: BaseItemDetailStore {
    public static let shared = ItemDetailStore()

    private var dataStore: DataStore
    private var sizeClassStore: SizeClassStore
    private var lifecycleStore: LifecycleStore
    private var userDefaultStore: UserDefaultStore
    private var routeStore: RouteStore
    private var itemListDisplayStore: ItemListDisplayStore

    private var _passwordRevealed = BehaviorRelay<Bool>(value: false)
    private var _isEditing = BehaviorRelay<Bool>(value: false)
    private var _usernameEditValue = ReplaySubject<String>.create(bufferSize: 1)
    private var _passwordEditValue = ReplaySubject<String>.create(bufferSize: 1)
    private var _webAddressEditValue = ReplaySubject<String>.create(bufferSize: 1)

    lazy private(set) var passwordRevealed: Observable<Bool> = {
        return self._passwordRevealed.asObservable()
    }()

    lazy private(set) var isEditing: Observable<Bool> = {
        return self._isEditing.asObservable()
    }()

    // RootPresenter needs a synchronous way to find out if the detail screen has a login or not
    var itemDetailHasId: Bool {
        return self._itemDetailId.value != ""
    }

    var usernameEditValue: Observable<String> {
        return self._usernameEditValue.asObservable()
    }

    var passwordEditValue: Observable<String> {
        return self._passwordEditValue.asObservable()
    }

    var webAddressEditValue: Observable<String> {
        return self._webAddressEditValue.asObservable()
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

        setupItemDetailDisplayAction()
        setupItemEditAction()

        self.lifecycleStore.lifecycleEvents
                .filter { $0 == .background }
                .map { _ in false }
                .bind(to: self._passwordRevealed)
                .disposed(by: self.disposeBag)

        setupMainRouteAction()
        setupItemDeletedAction()
        setupSplitView()
    }

    private func setupItemDetailDisplayAction() {
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

        self.dispatcher.register
                .filterByType(class: ItemDetailDisplayAction.self)
                .map { action -> Bool? in
                    switch action {
                    case .editMode:
                        return true
                    case .viewMode:
                        return false
                    default:
                        return nil
                    }
                }
                .filterNil()
                .bind(to: self._isEditing)
                .disposed(by: self.disposeBag)
    }

    private func setupItemEditAction() {
        self.dispatcher.register
        .filterByType(class: ItemEditAction.self)
        .subscribe(onNext: { (action) in
            switch action {
            case .editUsername(let newVal):
                self._usernameEditValue.onNext(newVal)
            case .editPassword(let newVal):
                self._passwordEditValue.onNext(newVal)
            case .editWebAddress(let newVal):
                self._webAddressEditValue.onNext(newVal)
            }
        })
        .disposed(by: self.disposeBag)
    }

    private func setupMainRouteAction() {
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
    }

    private func setupItemDeletedAction() {
        self.itemListDisplayStore.listDisplay
        .filterByType(class: ItemDeletedAction.self)
        .filter { self._itemDetailId.value == $0.id }
        .subscribe(onNext: { (_) in
            self._itemDetailId.accept("")
        })
        .disposed(by: self.disposeBag)
    }

    private func setupSplitView() {
        // If the splitview is being show
        // then after sync, select one item from the datastore to show
        Observable.combineLatest(sizeClassStore.shouldDisplaySidebar,
                                 self.dataStore.list,
                                 self.itemDetailId,
                                 self.userDefaultStore.itemListSort)
            .filter({ (displayingSidebar, list, itemId, _) -> Bool in
                return displayingSidebar && list.count > 0 && itemId == ""
            })
            .subscribe(onNext: { (_, list, _, sort) in
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

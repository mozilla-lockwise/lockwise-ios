/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxOptional

class DataStore {
    public static let shared = DataStore()

    fileprivate let disposeBag = DisposeBag()
    fileprivate var itemList = BehaviorRelay<[String: Item]>(value: [:])
    fileprivate var initialized = BehaviorRelay<Bool>(value: false)
    fileprivate var opened = BehaviorRelay<Bool>(value: false)
    fileprivate var locked = BehaviorRelay<Bool>(value: true)

    public var onItemList: Observable<[Item]> {
        return self.itemList.asObservable()
                .map { itemDictionary -> [Item] in
                    return Array(itemDictionary.values)
                }
                .distinctUntilChanged { lhList, rhList in
                    return lhList == rhList
                }
    }

    public var onInitialized: Observable<Bool> {
        return self.initialized.asObservable().distinctUntilChanged()
    }

    public var onOpened: Observable<Bool> {
        return self.opened.asObservable().distinctUntilChanged()
    }

    public var onLocked: Observable<Bool> {
        return self.locked.asObservable().distinctUntilChanged()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        dispatcher.register
                .filterByType(class: DataStoreAction.self)
                .subscribe(onNext: { action in
                    switch action {
                    case .list(let list):
                        self.itemList.accept(list)
                    case .updated(let item):
                        self.itemList.take(1)
                                .map { items in
                                    guard let id = item.id else {
                                        return items
                                    }

                                    var updatedItems = items
                                    updatedItems[id] = item
                                    return updatedItems
                                }
                                .bind(to: self.itemList)
                                .disposed(by: self.disposeBag)
                    case .locked(let locked):
                        self.locked.accept(locked)
                    case .initialized(let initialized):
                        self.initialized.accept(initialized)
                    case .opened(let opened):
                        self.opened.accept(opened)
                    }
                })
                .disposed(by: self.disposeBag)
    }

    public func onItem(_ itemId: String) -> Observable<Item> {
        return self.itemList.asObservable()
                .map { items -> Item? in
                    return items[itemId]
                }
                .filterNil()
                .distinctUntilChanged()
    }
}

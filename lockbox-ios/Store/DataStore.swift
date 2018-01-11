/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class DataStore {
    public static let shared = DataStore()

    fileprivate let disposeBag = DisposeBag()
    fileprivate var itemList = Variable<[Item]>([])
    fileprivate var initialized = Variable<Bool>(false)
    fileprivate var locked = Variable<Bool>(true)

    public var onItemList:Observable<[Item]> {
        return self.itemList.asObservable()
                .distinctUntilChanged { lhList, rhList in
                    return lhList.elementsEqual(rhList)
                }
    }

    public var onInitialized:Observable<Bool> {
        return self.initialized.asObservable().distinctUntilChanged()
    }

    public var onLocked:Observable<Bool> {
        return self.locked.asObservable().distinctUntilChanged()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        dispatcher.register
                .filterByType(class: DataStoreAction.self)
                .subscribe(onNext: { action in
                    switch action {
                    case .list(let list):
                        self.itemList.value = list
                        break
                    case .locked(let locked):
                        self.locked.value = locked
                        break
                    case .initialized(let initialized):
                        self.initialized.value = initialized
                        break
                    }
                 })
                .disposed(by: self.disposeBag)
    }

    public func onItem(_ itemId:String) -> Observable<Item> {
        return self.itemList.asObservable()
                .flatMap { list in
                    Observable.from(list)
                }
                .filterByType(class: Item.self)
                .filter { item in
                    return item.id == itemId
                }
                .distinctUntilChanged()
    }
}

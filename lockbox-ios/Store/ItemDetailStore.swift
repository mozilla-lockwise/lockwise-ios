/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class ItemDetailStore: BaseItemDetailStore {
    public static let shared = ItemDetailStore()

    private var _itemDetailDisplay = ReplaySubject<ItemDetailDisplayAction>.create(bufferSize: 1)

    lazy private(set) var itemDetailDisplay: Driver<ItemDetailDisplayAction> = {
        return self._itemDetailDisplay.asDriver(onErrorJustReturn: .togglePassword(displayed: false))
    }()

    override init(dispatcher: Dispatcher = Dispatcher.shared) {
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
                    self._itemDetailId.onNext("")
                }
            }).disposed(by: self.disposeBag)
    }
}

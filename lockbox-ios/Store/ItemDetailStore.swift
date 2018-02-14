/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class ItemDetailStore {
    static let shared = ItemDetailStore()

    private var dispatcher: Dispatcher
    private var disposeBag = DisposeBag()

    private var _itemDetailDispay = ReplaySubject<ItemDetailDisplayAction>.create(bufferSize: 1)

    lazy private(set) var itemDetailDisplay: Driver<ItemDetailDisplayAction> = {
        return self._itemDetailDispay.asDriver(onErrorJustReturn: .togglePassword(displayed: false))
    }()

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher

        self.dispatcher.register
                .filterByType(class: ItemDetailDisplayAction.self)
                .bind(to: self._itemDetailDispay)
                .disposed(by: self.disposeBag)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class ItemListDisplayStore {
    static let shared = ItemListDisplayStore()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let _itemListDisplay = PublishSubject<ItemListDisplayAction>()

    public var listDisplay: Observable<ItemListDisplayAction> {
        return _itemListDisplay.asObservable()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher

        self.dispatcher.register
                .filterByType(class: ItemListDisplayAction.self)
                .bind(to: self._itemListDisplay)
                .disposed(by: self.disposeBag)
    }
}

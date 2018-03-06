/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class CopyDisplayStore {
    static let shared = CopyDisplayStore()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let _copyDisplay = PublishSubject<CopyDisplayAction>()

    public var copyDisplay: Driver<CopyDisplayAction> {
        return _copyDisplay.asDriver(onErrorJustReturn: CopyDisplayAction(fieldName: ""))
    }

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher

        self.dispatcher.register
                .filterByType(class: CopyDisplayAction.self)
                .bind(to: self._copyDisplay)
                .disposed(by: self.disposeBag)
    }
}

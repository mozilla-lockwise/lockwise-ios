/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class CopyConfirmationDisplayStore {
    static let shared = CopyConfirmationDisplayStore()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let _copyDisplay = PublishSubject<CopyConfirmationDisplayAction>()

    public var copyDisplay: Driver<CopyConfirmationDisplayAction> {
        return _copyDisplay.asDriver(onErrorJustReturn: CopyConfirmationDisplayAction(field: .password))
    }

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher

        self.dispatcher.register
                .filterByType(class: CopyConfirmationDisplayAction.self)
                .bind(to: self._copyDisplay)
                .disposed(by: self.disposeBag)
    }
}

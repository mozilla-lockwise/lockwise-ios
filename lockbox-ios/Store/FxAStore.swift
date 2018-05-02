/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class FxAStore {
    static let shared = FxAStore()

    private var dispatcher: Dispatcher
    private let disposeBag = DisposeBag()

    private var _fxADisplay = PublishSubject<FxADisplayAction>()

    public var fxADisplay: Observable<FxADisplayAction> {
        return _fxADisplay.distinctUntilChanged()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher

        self.dispatcher.register
                .filterByType(class: FxADisplayAction.self)
                .bind(to: _fxADisplay)
                .disposed(by: self.disposeBag)
    }
}

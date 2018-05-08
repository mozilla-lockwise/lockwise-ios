/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class LifecycleStore {
    static let shared = LifecycleStore()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let _lifecycleFilter = PublishSubject<LifecycleAction>()

    public var lifecycleFilter: Observable<LifecycleAction> {
        return _lifecycleFilter.asObservable()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher

        self.dispatcher.register
                .filterByType(class: LifecycleAction.self)
                .bind(to: self._lifecycleFilter)
                .disposed(by: self.disposeBag)
    }
}

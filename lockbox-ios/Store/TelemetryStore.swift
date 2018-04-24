/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class TelemetryStore {
    static let shared = TelemetryStore()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let _telemetryFilter = PublishSubject<TelemetryAction>()

    public var telemetryFilter: Observable<TelemetryAction> {
        return _telemetryFilter.asObservable()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher

        self.dispatcher.register
                .filterByType(class: TelemetryAction.self)
                .bind(to: self._telemetryFilter)
                .disposed(by: self.disposeBag)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class BaseItemDetailStore {
    internal var dispatcher: Dispatcher
    internal var disposeBag = DisposeBag()

    internal var _itemDetailId = ReplaySubject<String>.create(bufferSize: 1)

    lazy private(set) var itemDetailId: Observable<String> = {
        return self._itemDetailId.asObservable()
    }()

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher
        self._itemDetailId.onNext("")
    }
}

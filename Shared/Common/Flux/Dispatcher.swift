/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

class Dispatcher {
    static let shared = Dispatcher()

    fileprivate let storeDispatchSubject = PublishSubject<Action>()

    open var register: Observable<Action> {
        return self.storeDispatchSubject.asObservable()
    }

    open func dispatch(action: Action) {
#if DEBUG
        if let err = action as? ErrorAction {
            print(err.error)
        }
#endif

        self.storeDispatchSubject.onNext(action)
    }
}

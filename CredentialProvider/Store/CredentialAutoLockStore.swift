/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class AutoLockStore: BaseAutoLockStore {
    static let shared = AutoLockStore()

    override func initialized() {
        self.dispatcher.register
                .filter { action -> Bool in
                    // note: any future actions that should reset the timer will go here.
                    // for now, none of the CredentialProvider actions are good candidates.
                    return false
                }
                .subscribe(onNext: { [weak self] _ in
                    self?.resetTimer()
                })
                .disposed(by: self.disposeBag)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

class DataStore: BaseDataStore {
    private var dispatcher: Dispatcher
    
    public static let shared = DataStore()
    
    init(dispatcher: Dispatcher = .shared) {
        self.dispatcher = dispatcher
        super.init()
    }

    override func initialized() {
        self.dispatcher.register
                .filterByType(class: CredentialStatusAction.self)
                // when we get credential status actions, check the locked status
                .withLatestFrom(self.locked, resultSelector: { (_, locked) -> Void? in
                    // if we are already locked, do not store the next lock time
                    return locked ? nil : ()
                })
                .filterNil()
                .subscribe(onNext: { [weak self] _ in
                    self?.autoLockSupport.storeNextAutolockTime()
                })
                .disposed(by: self.disposeBag)
    }
}

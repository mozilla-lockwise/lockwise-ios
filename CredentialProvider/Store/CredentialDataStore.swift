/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class DataStore: BaseDataStore {
    public static let shared = DataStore()
    
    override func initialized() {
        self.dispatcher.register
                .filterByType(class: LifecycleAction.self)
                .subscribe(onNext: { [weak self] action in
                    switch action {
                    case .foreground:
                        self?.handleLock()
                    default:
                        break
                    }
                })
                .disposed(by: self.disposeBag)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class DataStore: BaseDataStore {
    public static let shared = DataStore()

    override func unlock() {
        func performUnlock() {
            self.storageStateSubject.onNext(.Unlocked)
            self.profile.reopen()
            self.profile.syncManager?.beginTimedSyncs()
            self.profile.syncManager.syncEverything(why: .startup)
        }

        self.storageState
            .take(1)
            .subscribe(onNext: {
                if $0 == .Locked {
                    performUnlock()
                }
            })
            .disposed(by: self.disposeBag)
    }
}

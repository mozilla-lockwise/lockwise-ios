/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class DataStore: BaseDataStore {
    public static let shared = DataStore()

    override func initialized() { }

    override func unlock() {
        func performUnlock() {
            do {
                if let loginsKey = BaseDataStore.loginsKey {
                    try self.loginsStorage?.unlock(withEncryptionKey: loginsKey)
                    self.storageStateSubject.onNext(.Unlocked)
                    self.doSync()
                }
            } catch let error {
                print("Sync15: \(error)")
            }
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

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import MozillaAppServices

public protocol LoginsStorageProtocol {
    func close()
    func isLocked() -> Bool
    func ensureUnlocked(withEncryptionKey key: String) throws
    func ensureLocked()
    func sync(unlockInfo: SyncUnlockInfo) throws
    func wipeLocal() throws
    func get(id: String) throws -> LoginRecord?
    func touch(id: String) throws
    func list() throws -> [LoginRecord]
}

extension LoginsStorage: LoginsStorageProtocol { }

class DataStoreSupport {
    static let shared: DataStoreSupport = DataStoreSupport()

    open func createLoginsStorage(databasePath: String) -> LoginsStorageProtocol {
        return LoginsStorage(databasePath: databasePath)
    }
}

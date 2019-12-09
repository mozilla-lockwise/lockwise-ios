/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import RxSwift
import RxCocoa
import MozillaAppServices

enum DataStoreAction: Action {
    case updateCredentials(syncInfo: SyncCredential)
    case lock
    case unlock
    case reset
    case syncStart
    case touch(id: String)
    case delete(id: String)
    case update(login: LoginRecord)
    case syncEnd
    case syncTimeout
    case syncError(error: String)
}

extension DataStoreAction: TelemetryAction {
    var eventMethod: TelemetryEventMethod {
        switch(self) {
        case .updateCredentials:
            return .update_credentials
        case .lock:
            return .lock
        case .unlock:
            return .unlock
        case .reset:
            return .reset
        case .syncStart:
            return .sync
        case .touch:
            return .touch
        case .delete:
            return .delete
        case .syncEnd:
            return .sync_end
        case .syncTimeout:
            return .sync_timeout
        case .syncError:
            return .sync_error
        case .update:
            return .edit
        }
    }

    var eventObject: TelemetryEventObject {
        return .datastore
    }

    var value: String? {
        switch(self) {
        case .delete(let id):
            return id
        case .touch(let id):
            return "ID: \(id)"
        case .syncError(let error):
            return error
        default:
            return nil
        }
    }

    var extras: [String : Any?]? {
        return nil
    }
}

extension DataStoreAction: Equatable {
    static func ==(lhs: DataStoreAction, rhs: DataStoreAction) -> Bool {
        switch (lhs, rhs) {
        case (.updateCredentials, .updateCredentials): return true // TODO equality
        case (.lock, .lock): return true
        case (.unlock, .unlock): return true
        case (.reset, .reset): return true
        case (.syncStart, .syncStart): return true
        case (.touch(let lhID), .touch(let rhID)):
            return lhID == rhID
        case (.delete(let lhID), .delete(let rhID)):
            return lhID == rhID
        case (.update(let lhLogin), .update(let rhLogin)):
            return lhLogin == rhLogin
        case (.syncEnd, .syncEnd): return true
        case (.syncTimeout, .syncTimeout): return true
        case (.syncError(let lhError), .syncError(let rhError)):
            return lhError == rhError
        default: return false
        }
    }
}

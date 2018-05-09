/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import RxSwift
import RxCocoa
import Storage
import SwiftyJSON

enum DataStoreAction: Action {
    case initialize(blob: JSON)
    case lock
    case unlock
    case reset
    case sync
    case touch(id: String)
    case add(item: LoginData)
    case remove(id: String)
}

extension DataStoreAction: Equatable {
    static func ==(lhs: DataStoreAction, rhs: DataStoreAction) -> Bool {
        switch (lhs, rhs) {
        case (.initialize(let lhBlob), .initialize(let rhBlob)):
            return lhBlob == rhBlob
        case (.lock, .lock): return true
        case (.unlock, .unlock): return true
        case (.reset, .reset): return true
        case (.sync, .sync): return true
        case (.touch(let lhID), .touch(let rhID)):
            return lhID == rhID
        case (.add, .add):
            return true
        case (.remove(let lhID), .remove(let rhID)):
            return lhID == rhID
        default: return false
        }
    }
}

class DataStoreActionHandler: ActionHandler {
    static let shared = DataStoreActionHandler()
    private var dispatcher: Dispatcher

    private let disposeBag = DisposeBag()

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher
    }

    func invoke(_ action: DataStoreAction) {
        self.dispatcher.dispatch(action: action)
    }
}

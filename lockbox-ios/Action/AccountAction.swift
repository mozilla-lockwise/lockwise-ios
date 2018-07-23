/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxOptional
import FxAClient

enum AccountAction: Action {
    // invoked when redirecting from a successful OAuth authentication
    case oauthRedirect(url: URL)
    case clear
}

extension AccountAction: Equatable {
    static func ==(lhs: AccountAction, rhs: AccountAction) -> Bool {
        switch (lhs, rhs) {
        case (.oauthRedirect(let lhURL), .oauthRedirect(let rhURL)):
            return lhURL == rhURL
        case (.clear, .clear):
            return true
        default:
            return false
        }
    }
}

class AccountActionHandler: ActionHandler {
    static let shared = AccountActionHandler()
    fileprivate var dispatcher: Dispatcher
    fileprivate let disposeBag = DisposeBag()

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher
    }

    func invoke(_ action: AccountAction) {
        self.dispatcher.dispatch(action: action)
    }
}

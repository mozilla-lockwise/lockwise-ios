/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxOptional
import FxAClient

enum UserInfoAction: Action {
    case profileInfo(info: Profile)
    case load
    case clear
}

extension UserInfoAction: Equatable {
    static func ==(lhs: UserInfoAction, rhs: UserInfoAction) -> Bool {
        switch (lhs, rhs) {
        case (.profileInfo(let lhInfo), .profileInfo(let rhInfo)):
            return lhInfo == rhInfo
        case (.load, .load):
            return true
        case (.clear, .clear):
            return true
        default:
            return false
        }
    }
}

class UserInfoActionHandler: ActionHandler {
    static let shared = UserInfoActionHandler()
    fileprivate var dispatcher: Dispatcher
    fileprivate let disposeBag = DisposeBag()

    init(dispatcher: Dispatcher = Dispatcher.shared) {
        self.dispatcher = dispatcher
    }

    func invoke(_ action: UserInfoAction) {
        self.dispatcher.dispatch(action: action)
    }
}

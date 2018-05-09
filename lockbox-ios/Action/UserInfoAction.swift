/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxOptional
import Account
import FxAUtils

enum UserInfoAction: Action {
    case profileInfo(info: ProfileInfo)
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

    init(dispatcher: Dispatcher = Dispatcher.shared,
         notificationCenter: NotificationCenter = NotificationCenter.default) {
        self.dispatcher = dispatcher

        notificationCenter.rx
                .notification(NotificationNames.FirefoxAccountProfileChanged)
                .map { notification -> FirefoxAccount.FxAProfile? in
                    let account = notification.object as? FirefoxAccount
                    return account?.fxaProfile
                }
                .filterNil()
                .map { profile -> ProfileInfo in
                    return ProfileInfo.Builder()
                            .email(profile.email)
                            .avatar(profile.avatar.url)
                            .displayName(profile.displayName)
                            .build()
                }
                .subscribe(onNext: { profile in
                    self.dispatcher.dispatch(action: UserInfoAction.profileInfo(info: profile))
                })
                .disposed(by: self.disposeBag)
    }

    func invoke(_ action: UserInfoAction) {
        self.dispatcher.dispatch(action: action)
    }
}

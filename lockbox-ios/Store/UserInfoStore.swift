/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import SwiftKeychainWrapper

enum KeychainKey: String {
    case email, displayName, avatarURL

    static let allValues: [KeychainKey] = [.email, .displayName, .avatarURL]
}

class UserInfoStore {
    static let shared = UserInfoStore()

    private var dispatcher: Dispatcher
    private var keychainWrapper: KeychainWrapper
    private let disposeBag = DisposeBag()

    private var _profileInfo = ReplaySubject<ProfileInfo?>.create(bufferSize: 1)

    public var profileInfo: Observable<ProfileInfo?> {
        return _profileInfo.asObservable()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared,
         keychainWrapper: KeychainWrapper = KeychainWrapper.standard) {
        self.dispatcher = dispatcher
        self.keychainWrapper = keychainWrapper

        self.dispatcher.register
                .filterByType(class: UserInfoAction.self)
                .subscribe(onNext: { action in
                    switch action {
                    case .profileInfo(let info):
                        if self.saveProfileInfo(info) {
                            self._profileInfo.onNext(info)
                        }
                    case .load:
                        self.populateInitialValues()
                    case .clear:
                        self.clear()
                    }
                })
                .disposed(by: self.disposeBag)

    }
}

extension UserInfoStore {
    private func populateInitialValues() {
        if let email = self.keychainWrapper.string(forKey: KeychainKey.email.rawValue) {
            var avatarURL: URL?
            if let avatarString = self.keychainWrapper.string(forKey: KeychainKey.avatarURL.rawValue) {
                avatarURL = URL(string: avatarString)
            }

            let displayName = self.keychainWrapper.string(forKey: KeychainKey.displayName.rawValue)

            self._profileInfo.onNext(
                    ProfileInfo.Builder()
                            .email(email)
                            .avatar(avatarURL)
                            .displayName(displayName)
                            .build()
            )
        } else {
            self._profileInfo.onNext(nil)
        }
    }

    private func clear() {
        for identifier in KeychainKey.allValues {
            _ = self.keychainWrapper.removeObject(forKey: identifier.rawValue)
        }

        self._profileInfo.onNext(nil)
    }

    private func saveProfileInfo(_ info: ProfileInfo) -> Bool {
        var success = self.keychainWrapper.set(info.email, forKey: KeychainKey.email.rawValue)

        if let displayName = info.displayName {
            success = success && self.keychainWrapper.set(displayName, forKey: KeychainKey.displayName.rawValue)
        }

        if let avatar = info.avatar {
            let avatarString = avatar.absoluteString
            success = success && self.keychainWrapper.set(avatarString, forKey: KeychainKey.avatarURL.rawValue)
        }

        return success
    }
}

enum AutoLockSetting: String {
    case OneMinute
    case FiveMinutes
    case OneHour
    case TwelveHours
    case TwentyFourHours
    case Never

    func toString() -> String {
        switch self {
        case .FiveMinutes:
            return Constant.string.autoLockFiveMinutes
        case .Never:
            return Constant.string.autoLockNever
        case .OneHour:
            return Constant.string.autoLockOneHour
        case .OneMinute:
            return Constant.string.autoLockOneMinute
        case .TwelveHours:
            return Constant.string.autoLockTwelveHours
        case .TwentyFourHours:
            return Constant.string.autoLockTwentyFourHours
        }
    }
}

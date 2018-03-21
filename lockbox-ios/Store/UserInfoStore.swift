/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class UserInfoStore {
    static let shared = UserInfoStore()

    private var dispatcher: Dispatcher
    private var keychainManager: KeychainManager
    private let disposeBag = DisposeBag()

    private var _scopedKey = ReplaySubject<String?>.create(bufferSize: 1)
    private var _profileInfo = ReplaySubject<ProfileInfo?>.create(bufferSize: 1)
    private var _oauthInfo = ReplaySubject<OAuthInfo?>.create(bufferSize: 1)
    private var _biometricLoginEnabled = ReplaySubject<Bool?>.create(bufferSize: 1)

    public var scopedKey: Observable<String?> {
        return _scopedKey.asObservable()
    }

    public var profileInfo: Observable<ProfileInfo?> {
        return _profileInfo.asObservable()
    }

    public var oauthInfo: Observable<OAuthInfo?> {
        return _oauthInfo.asObservable()
    }

    public var biometricLoginEnabled: Observable<Bool?> {
        return _biometricLoginEnabled.asObservable()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared,
         keychainManager: KeychainManager = KeychainManager()) {
        self.dispatcher = dispatcher
        self.keychainManager = keychainManager

        self.dispatcher.register
                .filterByType(class: UserInfoAction.self)
                .subscribe(onNext: { action in
                    switch action {
                    case .profileInfo(let info):
                        if self.keychainManager.save(info.email, identifier: .email) &&
                                   self.keychainManager.save(info.uid, identifier: .uid) {
                            self._profileInfo.onNext(info)
                        }
                    case .oauthInfo(let info):
                        if self.keychainManager.save(info.accessToken, identifier: .accessToken) &&
                                   self.keychainManager.save(info.idToken, identifier: .idToken) &&
                                   self.keychainManager.save(info.refreshToken, identifier: .refreshToken) {
                            self._oauthInfo.onNext(info)
                        }
                    case .scopedKey(let scopedKey):
                        if self.keychainManager.save(scopedKey, identifier: .scopedKey) {
                            self._scopedKey.onNext(scopedKey)
                        }
                    case .load:
                        self.populateInitialValues()
                    case .clear:
                        self.clear()
                    case .biometricLogin(let enabled):
                        if self.keychainManager.save(enabled.description, identifier: .biometricLoginEnabled) {
                            self._biometricLoginEnabled.onNext(enabled)
                        }
                    }
                })
                .disposed(by: self.disposeBag)

    }

    private func populateInitialValues() {
        if let email = self.keychainManager.retrieve(.email),
           let uid = self.keychainManager.retrieve(.uid) {
            self._profileInfo.onNext(
                    ProfileInfo.Builder()
                            .uid(uid)
                            .email(email)
                            .build()
            )
        } else {
            self._profileInfo.onNext(nil)
        }

        self._scopedKey.onNext(self.keychainManager.retrieve(.scopedKey))

        if let accessToken = self.keychainManager.retrieve(.accessToken),
           let idToken = self.keychainManager.retrieve(.idToken),
           let refreshToken = self.keychainManager.retrieve(.refreshToken) {
            self._oauthInfo.onNext(
                    OAuthInfo.Builder()
                            .refreshToken(refreshToken)
                            .idToken(idToken)
                            .accessToken(accessToken)
                            .build()
            )
        } else {
            self._oauthInfo.onNext(nil)
        }

        let enabled = self.keychainManager.retrieve(.biometricLoginEnabled)
        if enabled == nil {
            self._biometricLoginEnabled.onNext(nil)
        } else {
            self._biometricLoginEnabled.onNext(enabled == "true")
        }
    }

    private func clear() {
        for identifier in KeychainManagerIdentifier.allValues {
            _ = self.keychainManager.delete(identifier)
        }

        self._profileInfo.onNext(nil)
        self._oauthInfo.onNext(nil)
        self._profileInfo.onNext(nil)
    }
}

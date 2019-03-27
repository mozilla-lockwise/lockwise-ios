/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import FxAClient
import SwiftKeychainWrapper
import WebKit
import Logins

class BaseAccountStore {
    internal var keychainWrapper: KeychainWrapper

    internal var fxa: FirefoxAccount?
    internal var _syncCredentials = ReplaySubject<SyncUnlockInfo?>.create(bufferSize: 1)
    internal var _profile = ReplaySubject<Profile?>.create(bufferSize: 1)

    public var syncCredentials: Observable<SyncUnlockInfo?> {
        return _syncCredentials.asObservable()
    }

    public var profile: Observable<Profile?> {
        return _profile.asObservable()
    }

    internal var storedAccountJSON: String? {
        let key = KeychainKey.accountJSON.rawValue

        return self.keychainWrapper.string(forKey: key)
    }

    init(keychainWrapper: KeychainWrapper = KeychainWrapper.sharedAppContainerKeychain) {
        self.keychainWrapper = keychainWrapper

        self.initialized()
    }

    internal func initialized() {
        fatalError("not implemented!")
    }

    internal func populateAccountInformation() {
        guard let fxa = self.fxa else {
            return
        }

        fxa.getAccessToken(scope: Constant.fxa.lockboxScope) { [weak self] (accessToken, err) in
            guard let key = accessToken?.key,
                let token = accessToken?.token
                else { return }

            guard let tokenURL = try? self?.fxa?.getTokenServerEndpointURL() else { return }

            self?._syncCredentials.onNext(
                SyncUnlockInfo(
                    kid: key.kid,
                    fxaAccessToken: token,
                    syncKey: key.k,
                    tokenserverURL: tokenURL!.absoluteString
                )
            )

            if let accountJSON = try? fxa.toJSON() {
                self?.keychainWrapper.set(accountJSON, forKey: KeychainKey.accountJSON.rawValue)
            }
        }

        fxa.getProfile { (profile: Profile?, _) in
            self._profile.onNext(profile)
        }
    }
}

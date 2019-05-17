/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import MozillaAppServices
import SwiftKeychainWrapper
import WebKit

class BaseAccountStore {
    internal var keychainWrapper: KeychainWrapper
    internal let networkStore: NetworkStore

    internal var fxa: FirefoxAccount?
    internal var _syncCredentials = ReplaySubject<SyncCredential?>.create(bufferSize: 1)
    internal var _profile = ReplaySubject<Profile?>.create(bufferSize: 1)

    public var syncCredentials: Observable<SyncCredential?> {
        return _syncCredentials.asObservable()
    }

    public var profile: Observable<Profile?> {
        return _profile.asObservable()
    }

    internal var storedAccountJSON: String? {
        let key = KeychainKey.accountJSON.rawValue

        return self.keychainWrapper.string(forKey: key)
    }

    init(keychainWrapper: KeychainWrapper = KeychainWrapper.sharedAppContainerKeychain,
         networkStore: NetworkStore = NetworkStore.shared) {
        self.keychainWrapper = keychainWrapper
        self.networkStore = networkStore

        self.initialized()
    }

    internal func initialized() {
        fatalError("not implemented!")
    }

    internal func populateAccountInformation(_ isNew: Bool) {
        guard let fxa = self.fxa else {
            return
        }

        if !networkStore.isConnectedToNetwork {
            self._syncCredentials.onNext(OfflineSyncCredential)
            return
        }

        fxa.getAccessToken(scope: Constant.fxa.oldSyncScope) { [weak self] (accessToken, err) in
            if let error = err {
                NSLog("Unexpected error getting access token: \(error.localizedDescription)")
                self?._syncCredentials.onNext(nil)
            }

            guard let key = accessToken?.key,
                let token = accessToken?.token
                else { return }

            guard let tokenURL = try? self?.fxa?.getTokenServerEndpointURL() else { return }

            let syncInfo = SyncUnlockInfo(
                kid: key.kid,
                fxaAccessToken: token,
                syncKey: key.k,
                tokenserverURL: tokenURL!.absoluteString
            )

            self?._syncCredentials.onNext(
                SyncCredential(syncInfo: syncInfo, isNew: isNew)
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

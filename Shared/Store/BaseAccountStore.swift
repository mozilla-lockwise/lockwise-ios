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
    internal let networkHelper: NetworkHelper

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
         networkHelper: NetworkHelper = NetworkHelper.shared) {
        self.keychainWrapper = keychainWrapper
        self.networkHelper = networkHelper

        self.initialized()
    }

    internal func initialized() {
        fatalError("not implemented!")
    }

    internal func populateAccountInformation(_ isNew: Bool) {
        guard let fxa = self.fxa else {
            return
        }

        if !networkHelper.isConnectedToNetwork {
            self._syncCredentials.onNext(OfflineSyncCredential)
            return
        }

        fxa.getAccessToken(scope: Constant.fxa.oldSyncScope) { [weak self] (accessToken, err) in
            if let err = err as? FirefoxAccountError,
                case .Network = err {
                self?._syncCredentials.onNext(OfflineSyncCredential)
                // no token refresh has occurred, so we won't worry about re-saving
                // the firefox account at this stage
                return
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

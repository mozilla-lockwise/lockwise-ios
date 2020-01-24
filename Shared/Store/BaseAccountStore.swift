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
    internal let dispatcher: Dispatcher
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

    init(dispatcher: Dispatcher = .shared,
         keychainWrapper: KeychainWrapper = KeychainWrapper.sharedAppContainerKeychain,
         networkStore: NetworkStore = NetworkStore.shared) {
        self.dispatcher = dispatcher
        self.keychainWrapper = keychainWrapper
        self.networkStore = networkStore

        self.initialized()
    }

    internal func initialized() {
        fatalError("not implemented!")
    }

    internal func populateAccountInformation(_ isNew: Bool) {
        var errMessage = "Autofill error: BaseAccountStore: "
        guard let fxa = self.fxa else {
            errMessage = errMessage + "fxa is nil"
            sendSentryEvent(title: errMessage, error: nil)
            return
        }

        fxa.getProfile { [weak self] (profile: Profile?, error) in
            self?._profile.onNext(profile)
            if profile == nil {
                self?.sendSentryEvent(title: errMessage + "profile is nil", error: error)
            }
        }

        if !networkStore.isConnectedToNetwork {
            self._syncCredentials.onNext(OfflineSyncCredential)
            errMessage = errMessage + "isConnectedToNetwork false"
            sendSentryEvent(title: errMessage, error: nil)
            return
        }

        fxa.getAccessToken(scope: Constant.fxa.oldSyncScope) { [weak self] (accessToken, err) in
            if let error = err as? FirefoxAccountError {
                switch error {
                case .network(let message):
                    errMessage = errMessage + "Network error: " + message
                case .unspecified(let message):
                    errMessage = errMessage + "Unspecified error: " + message
                case .unauthorized(let message):
                    errMessage = errMessage + "Unauthorized error: " + message
                case .panic(let message):
                    errMessage = errMessage + "Panic error: " + message
                }
                self?.sendSentryEvent(title: "FxAException: " + errMessage, error: error)
                NSLog("Unexpected error getting access token: \(error.localizedDescription)")
                self?._syncCredentials.onNext(nil)
            } else if let error = err {
                self?.sendSentryEvent(title: errMessage + "Unexpected exception: ", error: error)
                self?._syncCredentials.onNext(nil)
            }

            guard let key = accessToken?.key else {
                self?.sendSentryEvent(title: errMessage + "key is nil", error: nil)
                self?._syncCredentials.onNext(nil)
                return
            }
            guard let token = accessToken?.token else {
                self?.sendSentryEvent(title: errMessage + "token is nil", error: nil)
                self?._syncCredentials.onNext(nil)
                return
            }
            
            guard let tokenURL = try? self?.fxa?.getTokenServerEndpointURL() else {
                self?.sendSentryEvent(title: errMessage + "tokenURL is nil", error: nil)
                self?._syncCredentials.onNext(nil)
                return
            }

            let syncInfo = SyncUnlockInfo(
                kid: key.kid,
                fxaAccessToken: token,
                syncKey: key.k,
                tokenserverURL: tokenURL.absoluteString
            )

            self?._syncCredentials.onNext(
                SyncCredential(syncInfo: syncInfo, isNew: isNew)
            )
            
            do {
                let accountJSON = try fxa.toJSON()
                self?.keychainWrapper.set(accountJSON, forKey: KeychainKey.accountJSON.rawValue)
            } catch {
                self?.sendSentryEvent(title: errMessage + "fxa to JSON failed", error: error)
            }
            
        }
    }
    
    private func sendSentryEvent(title: String, error: Error?) {
        let sentryAction = SentryAction(
            title: title,
            error: error,
            line: nil
        )
        dispatcher.dispatch(action: sentryAction)
    }
}

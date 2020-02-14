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
    
    private func setupRustLogging() {
        // Set up logging from Rust.
        if !RustLog.shared.tryEnable({ (level, tag, message) -> Bool in
            let logString = "[RUST-LOG][\(tag ?? "no-tag")] \(message)"

            switch level {
            case .trace:
                NSLog(logString)
            case .debug:
                NSLog(logString)
            case .info:
                NSLog(logString)
            case .warn:
                NSLog(logString)
            case .error:
                self.sendSentryEvent(title: logString, error: nil)
                NSLog("LOGGING RUST ERROR: \(logString)")
            }
            return true
        }) {
            NSLog("ERROR: Unable to enable logging from Rust")
        }

        // By default, filter logging from Rust below `.info` level.
        try? RustLog.shared.setLevelFilter(filter: .info)
    }

    internal func initialized() {
        fatalError("not implemented!")
    }

    internal func populateAccountInformation(_ isNew: Bool) {
        let autofillLogPrefix = "Autofill-1070: "
        var errMessage = "Autofill error: BaseAccountStore: "
        
        NSLog("\(autofillLogPrefix) AS001 - starting to populate account information")
        guard let fxa = self.fxa else {
            errMessage = errMessage + "fxa is nil"
            NSLog("\(autofillLogPrefix) ASError - \(errMessage)")
            sendSentryEvent(title: errMessage, error: nil)
            return
        }
        NSLog("\(autofillLogPrefix) AS002 - about to call fxa.getProfile")
        fxa.getProfile { [weak self] (profile: Profile?, error) in
            self?._profile.onNext(profile)
            if profile == nil {
                NSLog("\(autofillLogPrefix) ASError - \(errMessage) profile is nil")
                self?.sendSentryEvent(title: errMessage + "profile is nil", error: error)
            } else {
                NSLog("\(autofillLogPrefix) AS003 - fxa profile is not nil")
            }
        }

        if !networkStore.isConnectedToNetwork {
            NSLog("\(autofillLogPrefix) ASError - isConnectedToNetwork false - BaseAccountStore line 98")
            self._syncCredentials.onNext(OfflineSyncCredential)
            errMessage = errMessage + "isConnectedToNetwork false"
            sendSentryEvent(title: errMessage, error: nil)
            return
        } else {
            NSLog("\(autofillLogPrefix) AS004 - connected to network - getting access token")
        }

        fxa.getAccessToken(scope: Constant.fxa.oldSyncScope) { [weak self] (accessToken, err) in
            NSLog("\(autofillLogPrefix) AS005 - entering fxa.getAccessToken closure")
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
                NSLog("\(autofillLogPrefix) ASError - FxAException: \(errMessage)")
                self?.sendSentryEvent(title: "FxAException: " + errMessage, error: error)
                NSLog("Unexpected error getting access token: \(error.localizedDescription)")
                self?._syncCredentials.onNext(nil)
            } else if let error = err {
                NSLog("\(autofillLogPrefix) ASError - Unexpected exception: \(error.localizedDescription)")
                self?.sendSentryEvent(title: errMessage + "Unexpected exception: ", error: error)
                self?._syncCredentials.onNext(nil)
            }
            NSLog("\(autofillLogPrefix) AS006 - no error in fxa.getAccessToken, about to unwrap key data")
            guard let key = accessToken?.key else {
                NSLog("\(autofillLogPrefix) ASError - accessToken.key is nil")
                self?.sendSentryEvent(title: errMessage + "key is nil", error: nil)
                self?._syncCredentials.onNext(nil)
                return
            }
            NSLog("\(autofillLogPrefix) AS007 - unwrapped accessToken.key successfully")
            guard let token = accessToken?.token else {
                NSLog("\(autofillLogPrefix) ASError - accessToken.token is nil")
                self?.sendSentryEvent(title: errMessage + "token is nil", error: nil)
                self?._syncCredentials.onNext(nil)
                return
            }
            NSLog("\(autofillLogPrefix) AS008 - unwrapped accessToken.token successfully")
            guard let tokenURL = try? self?.fxa?.getTokenServerEndpointURL() else {
                NSLog("\(autofillLogPrefix) ASError - tokenURL is nil")
                self?.sendSentryEvent(title: errMessage + "tokenURL is nil", error: nil)
                self?._syncCredentials.onNext(nil)
                return
            }
            NSLog("\(autofillLogPrefix) AS009 - unwrapped tokenURL successfully")
            let syncInfo = SyncUnlockInfo(
                kid: key.kid,
                fxaAccessToken: token,
                syncKey: key.k,
                tokenserverURL: tokenURL.absoluteString
            )
            NSLog("\(autofillLogPrefix) AS010 - sending syncCredentials.onNext")
            self?._syncCredentials.onNext(
                SyncCredential(syncInfo: syncInfo, isNew: isNew)
            )
            NSLog("\(autofillLogPrefix) AS011 - about to try fxa.toJSON")
            do {
                let accountJSON = try fxa.toJSON()
                NSLog("\(autofillLogPrefix) AS012 - fxa.toJSON successful, setting KeychainKey")
                self?.keychainWrapper.set(accountJSON, forKey: KeychainKey.accountJSON.rawValue)
            } catch {
                NSLog("\(autofillLogPrefix) ASError - fxa.toJSON failed: \(error.localizedDescription)")
                self?.sendSentryEvent(title: errMessage + "fxa to JSON failed", error: error)
            }
            NSLog("\(autofillLogPrefix) AS013 - leaving populationAccountInformation()")
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

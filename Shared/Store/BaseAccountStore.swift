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
    internal var _oauthInfo = ReplaySubject<SyncUnlockInfo?>.create(bufferSize: 1)
    internal var _profile = ReplaySubject<Profile?>.create(bufferSize: 1)
    internal var _account = ReplaySubject<FirefoxAccount?>.create(bufferSize: 1)

    public var oauthInfo: Observable<SyncUnlockInfo?> {
        return _oauthInfo.asObservable()
    }

    public var profile: Observable<Profile?> {
        return _profile.asObservable()
    }

    public var account: Observable<FirefoxAccount?> {
        return _account.asObservable()
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

        self._account.onNext(fxa)

        fxa.getAccessToken(scope: Constant.fxa.lockboxScope) { (info, err) in
            // convert to syncunlockinfo here?
//            self._oauthInfo.onNext()
            if let json = try? fxa.toJSON() {
                self.keychainWrapper.set(json, forKey: KeychainKey.accountJSON.rawValue)
            }
        }
//        { (info: OAuthInfo?, _) in
//            self._oauthInfo.onNext(info)
//

//        }

        fxa.getProfile { (profile: Profile?, _) in
            self._profile.onNext(profile)
        }
    }
}

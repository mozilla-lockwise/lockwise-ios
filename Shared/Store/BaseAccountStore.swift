/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import FxAClient
import SwiftKeychainWrapper
import WebKit

class BaseAccountStore {
    internal var sharedKeychainWrapper: KeychainWrapper

    internal var fxa: FirefoxAccount?
    internal var _oauthInfo = ReplaySubject<OAuthInfo?>.create(bufferSize: 1)
    internal var _profile = ReplaySubject<Profile?>.create(bufferSize: 1)

    public var oauthInfo: Observable<OAuthInfo?> {
        return _oauthInfo.asObservable()
    }
    
    public var profile: Observable<Profile?> {
        return _profile.asObservable()
    }

    internal var storedAccountJSON: String? {
        let key = KeychainKey.accountJSON.rawValue
        
        return self.sharedKeychainWrapper.string(forKey: key) ?? self.localKeychainWrapper.string(forKey: key)
    }

    init(sharedKeychainWrapper: KeychainWrapper = KeychainWrapper(serviceName: "", accessGroup: Constant.app.group)) {
        self.sharedKeychainWrapper = sharedKeychainWrapper

        self.initialized()
    }
    
    internal func initialized() {
        fatalError("not implemented!")
    }

    internal func populateAccountInformation() {
        guard let fxa = self.fxa else {
            return
        }

        fxa.getOAuthToken(scopes: Constant.fxa.scopes) { (info: OAuthInfo?, _) in
            self._oauthInfo.onNext(info)
            
            if let json = try? fxa.toJSON() {
                self.sharedKeychainWrapper.set(json, forKey: KeychainKey.accountJSON.rawValue)
            }
        }
        
        fxa.getProfile { (profile: Profile?, _) in
            self._profile.onNext(profile)
        }
    }
}

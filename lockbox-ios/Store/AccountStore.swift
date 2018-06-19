/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import FxAClient
import SwiftyJSON
import SwiftKeychainWrapper

enum KeychainKey: String {
    // note: these additional keys are holdovers from the previous Lockbox-owned style of
    // authentication
    case email, displayName, avatarURL, accountJSON

    static let allValues: [KeychainKey] = [.accountJSON, .email, .displayName, .avatarURL]
}

class AccountStore {
    static let shared = AccountStore()

    private var dispatcher: Dispatcher
    private var keychainWrapper: KeychainWrapper
    private let disposeBag = DisposeBag()

    private var _loginURL = ReplaySubject<URL>.create(bufferSize: 1)
    private var _profile = ReplaySubject<Profile?>.create(bufferSize: 1)
    private var _oauthInfo = ReplaySubject<OAuthInfo?>.create(bufferSize: 1)

    private lazy var fxa: FirefoxAccount? = {
        if let accountJSON = self.keychainWrapper.string(forKey: KeychainKey.accountJSON.rawValue),
                let fxa = try? FirefoxAccount.fromJSON(state: accountJSON) {
            return fxa
        }

        if let config = try? FxAConfig.custom(content_base: "https://accounts.firefox.com"),
              let fxa = try? FirefoxAccount(config: config, clientId: Constant.fxa.clientID) {
            return fxa
        }

        return nil
    }()

    public var loginURL: Observable<URL> {
        return _loginURL.asObservable()
    }

    public var profile: Observable<Profile?> {
        return _profile.asObservable()
    }

    public var oauthInfo: Observable<OAuthInfo?> {
        return _oauthInfo.asObservable()
    }

    init(dispatcher: Dispatcher = Dispatcher.shared,
         keychainWrapper: KeychainWrapper = KeychainWrapper.standard) {
        self.dispatcher = dispatcher
        self.keychainWrapper = keychainWrapper

        self.dispatcher.register
                .filterByType(class: AccountAction.self)
                .subscribe(onNext: { action in
                    switch action {
                    case .oauthRedirect(let url):
                        self.oauthLogin(url)
                    case .clear:
                        self.clear()
                    }
                })
                .disposed(by: self.disposeBag)

        self.generateInitialURL()
        self.populateInitialValues()
    }
}

extension AccountStore {
    private func generateInitialURL() {
        // TODO: it doesn't look like this library allows us to specify "signin" action?
        // the page is defaulting to signup :(
        if let url = try? self.fxa?.beginOAuthFlow(
                redirectURI: Constant.fxa.redirectURI,
                scopes: [
                    "profile",
                    "https://identity.mozilla.com/apps/oldsync",
                    "https://identity.mozilla.com/apps/lockbox"],
                wantsKeys: true),
           url != nil {
            self._loginURL.onNext(url!)
        }
    }

    private func populateInitialValues() {
        if let oauthInfo = try? self.fxa?.getOAuthToken(scopes: ["profile",
                                                                 "https://identity.mozilla.com/apps/oldsync",
                                                                 "https://identity.mozilla.com/apps/lockbox"]) {
            self._oauthInfo.onNext(oauthInfo)
        } else {
            self._oauthInfo.onNext(nil)
        }

        if let profile = try? self.fxa?.getProfile() {
            self._profile.onNext(profile)
        } else {
            self._profile.onNext(nil)
        }
    }

    private func clear() {
        for identifier in KeychainKey.allValues {
            _ = self.keychainWrapper.removeObject(forKey: identifier.rawValue)
        }

        self._profile.onNext(nil)
        self._oauthInfo.onNext(nil)
    }

    private func oauthLogin(_ navigationURL: URL) {
        guard let components = URLComponents(url: navigationURL, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return
        }

        var dic = [String: String]()
        queryItems.forEach {
            dic[$0.name] = $0.value
        }

        guard let code = dic["code"],
              let state = dic["state"],
              let fxa = self.fxa,
              let oauthInfo = try? fxa.completeOAuthFlow(code: code, state: state),
              let accountJSON = try? fxa.toJSON() else {
            self._oauthInfo.onNext(nil)
            return
        }
        self.keychainWrapper.set(accountJSON, forKey: KeychainKey.accountJSON.rawValue)
        self._oauthInfo.onNext(oauthInfo)

        // leaving this for posterity / possible usefulness but it will get deleted....
//        print("access_token: " + oauthInfo.accessToken)
//        let keys = JSON(parseJSON: oauthInfo.keys)
//        let scopedKey = keys[Constant.fxa.scope]
//
//        print("keysJWE: \(scopedKey)")
//
//        print("obtained scopes: " + oauthInfo.scopes.joined(separator: " "))

        guard let fxaProfile = try? fxa.getProfile() else {
            return
        }

        self._profile.onNext(fxaProfile)
    }
}

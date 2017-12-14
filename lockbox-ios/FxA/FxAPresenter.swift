/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import RxSwift

protocol FxAViewProtocol: class, ErrorView {
    func loadRequest(_ urlRequest:URLRequest)
}

enum FxAError : Error {
    case RedirectNoState, RedirectNoCode, RedirectBadState, EmptyOAuthData, EmptyProfileInfoData, UnexpectedDataFormat, Unknown
}

class FxAPresenter {
    weak var view:FxAViewProtocol!
    private var keyManager:KeyManager
    private var keychainManager:KeychainManager
    private var session:URLSession
    private var disposeBag = DisposeBag()

    internal let oauthHost = "oauth-scoped-keys-oct10.dev.lcip.org"
    internal let profileHost = "latest-keys.dev.lcip.org"
    internal let redirectURI = "lockbox://redirect.ios"
    internal let clientID = "98adfa37698f255b"
    internal let scope = "https://identity.mozilla.com/apps/lockbox"
    internal var state:String
    internal var codeVerifier:String

    private var jwkKey:String {
        get {
            return keyManager.getEphemeralPublicECDH().base64URL()
        }
    }
    private var codeChallenge:String { get { return codeVerifier.sha256withBase64URL()! } }

    private var authURL:URL {
        get {
            var components = URLComponents()

            components.scheme = "https"
            components.host = oauthHost
            components.path = "/v1/authorization"

            components.queryItems = [
                URLQueryItem(name: "response_type", value:"code"),
                URLQueryItem(name: "access_type", value: "offline"),
                URLQueryItem(name: "client_id", value: clientID),
                URLQueryItem(name: "redirect_uri", value: redirectURI),
                URLQueryItem(name: "scope", value:"profile:email openid \(scope)"),
                URLQueryItem(name: "keys_jwk", value: jwkKey),
                URLQueryItem(name: "state", value: state),
                URLQueryItem(name: "code_challenge", value: codeChallenge),
                URLQueryItem(name: "code_challenge_method", value: "S256")
            ]

            return components.url!
        }
    }

    private var tokenURL:URL {
        get {
            var components = URLComponents()

            components.scheme = "https"
            components.host = oauthHost
            components.path = "/v1/token"

            return components.url!
        }
    }

    private var profileInfoURL:URL {
        get {
            var components = URLComponents()
            components.scheme = "https"
            components.host = profileHost
            components.path = "/v1/profile"

            return components.url!
        }
    }

    init(session: URLSession = URLSession.shared, keyManager:KeyManager = KeyManager(), keychainManager:KeychainManager = KeychainManager()) {
        self.keyManager = keyManager
        self.keychainManager = keychainManager
        self.state = self.keyManager.random32()!.base64URLEncodedString()
        self.codeVerifier = self.keyManager.random32()!.base64URLEncodedString()
        self.session = session
    }

    func onViewReady() {
        let urlRequest = URLRequest(url: self.authURL)
        self.view.loadRequest(urlRequest)
    }

    func webViewRequest(decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let navigationURL = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if ("\(navigationURL.scheme!)://\(navigationURL.host!)" == redirectURI) {
            decisionHandler(.cancel)
            let components = URLComponents(url: navigationURL, resolvingAgainstBaseURL: true)!

            var code:String
            do {
                code = try validateQueryParamsForAuthCode(components.queryItems!)
            } catch {
                self.view.displayError(error)
                return
            }

            authenticateAndRetrieveUserInformation(code: code)
            return
        }

        decisionHandler(.allow)
    }

    private func authenticateAndRetrieveUserInformation(code: String) {
        self.postTokenRequest(code: code)
                .do(onNext: { info in
                    self.retrieveProfileInfo(accessToken: info.accessToken)
                }, onError: nil, onSubscribe: nil, onSubscribed: nil, onDispose: nil)
                .map { info -> String in
                    return try self.deriveScopedKeyFromJWE(info.keysJWE)
                }
                .subscribe(onSuccess: { scopedKey in
                    self.keychainManager.saveScopedKey(scopedKey)
                }, onError: { error in
                    self.view.displayError(error)
                })
                .disposed(by: self.disposeBag)
    }

    private func retrieveProfileInfo(accessToken: String) {
        postProfileInfoRequest(accessToken: accessToken)
                .subscribe(onSuccess: { info in
                    self.keychainManager.saveUserEmail(info.email)
                }, onError:{ error in
                    self.view.displayError(error)
                })
                .disposed(by: self.disposeBag)
    }

    private func postTokenRequest(code: String) -> Single<OAuthInfo> {
        var request = URLRequest(url: tokenURL)
        let requestParams = [
            "grant_type": "authorization_code",
            "client_id": clientID,
            "code": code,
            "code_verifier": codeVerifier
        ]

        let oauthSingle = Single<OAuthInfo>.create() { single in
            let disposable = Disposables.create()

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: requestParams)
            } catch {
                single(.error(error))
                return disposable
            }

            request.httpMethod = "POST"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let task = self.session.dataTask(with: request) { data, response, error in
                if error != nil {
                    single(.error(error!))
                    return
                }

                guard let data = data else {
                    single(.error(FxAError.EmptyOAuthData))
                    return
                }

                var oauthInfo:OAuthInfo
                do {
                    oauthInfo = try JSONDecoder().decode(OAuthInfo.self, from: data)
                } catch {
                    single(.error(error))
                    return
                }

                single(.success(oauthInfo))
            }

            task.resume()

            return disposable
        }

        return oauthSingle
    }

    private func postProfileInfoRequest(accessToken: String) -> Single<ProfileInfo> {
        var request = URLRequest(url: profileInfoURL)
        request.httpMethod = "GET"
        request.addValue("Bearer", forHTTPHeaderField: "Authorization \(accessToken)")

        let profileInfoSingle = Single<ProfileInfo>.create() { single in
            let disposable = Disposables.create()

            let task = self.session.dataTask(with: request) { data, response, error in
                if error != nil {
                    single(.error(error!))
                    return
                }

                guard let data = data else {
                    single(.error(FxAError.EmptyProfileInfoData))
                    return
                }

                var profileInfo: ProfileInfo
                do {
                    profileInfo = try JSONDecoder().decode(ProfileInfo.self, from: data)
                } catch {
                    single(.error(error))
                    return
                }

                single(.success(profileInfo))
            }

            task.resume()

            return disposable
        }

        return profileInfoSingle
    }

    private func deriveScopedKeyFromJWE(_ jwe: String) throws -> String {
        let jweString = self.keyManager.decryptJWE(jwe)

        guard let jsonValue = try JSONSerialization.jsonObject(with: jweString.data(using: .utf8)!) as? [String:Any],
              let jweJSON = jsonValue[scope] as? [String:Any],
              let key = jweJSON["k"] as? String else {
            throw FxAError.UnexpectedDataFormat
        }

        return key
    }

    private func validateQueryParamsForAuthCode(_ redirectParams: [URLQueryItem]) throws -> String {
        guard let state = redirectParams.first(where: { $0.name == "state"}) else {
            throw FxAError.RedirectNoState
        }

        guard let code = redirectParams.first(where: { $0.name == "code"}),
              let codeValue = code.value else {
            throw FxAError.RedirectNoCode
        }

        guard state.value == self.state else {
            throw FxAError.RedirectBadState
        }

        return codeValue
    }
}

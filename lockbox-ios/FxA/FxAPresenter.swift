/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import RxSwift

protocol FxAViewProtocol: class {
    func loadRequest(_ urlRequest:URLRequest)
}

enum FxAError : Error {
    case RedirectNoState, RedirectNoCode, RedirectBadState, EmptyOAuthData, UnexpectedDataFormat, Unknown
}

class FxAPresenter {
    weak var view:FxAViewProtocol?
    private var keyManager:KeyManager
    private var session:URLSession
    private var scopedKeySubject = PublishSubject<OAuthInfo>()

    internal let oauthHost = "oauth-scoped-keys-oct10.dev.lcip.org"
    internal let profileHost = "latest-keys.dev.lcip.org"
    internal let redirectURI = "lockbox://redirect.ios"
    internal let clientID = "98adfa37698f255b"
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
                URLQueryItem(name: "scope", value:"profile:email openid https://identity.mozilla.com/apps/lockbox"),
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

    init(session: URLSession = URLSession.shared, keyManager:KeyManager = KeyManager()) {
        self.keyManager = keyManager
        self.state = self.keyManager.random32()!.base64URLEncodedString()
        self.codeVerifier = self.keyManager.random32()!.base64URLEncodedString()
        self.session = session
    }

    func authenticateAndRetrieveScopedKey() -> Single<OAuthInfo> {
        let urlRequest = URLRequest(url: self.authURL)
        self.view!.loadRequest(urlRequest)

        return scopedKeySubject.asSingle()
    }

    func webViewRequest(decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let navigationURL = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if ("\(navigationURL.scheme!)://\(navigationURL.host!)" == redirectURI) {
            let components = URLComponents(url: navigationURL, resolvingAgainstBaseURL: true)!
            if let code = validateQueryParamsForAuthCode(components.queryItems!) {
                postTokenRequest(code: code)
            }
            decisionHandler(.cancel)
            return
        }

        decisionHandler(.allow)
    }

    private func validateQueryParamsForAuthCode(_ redirectParams: [URLQueryItem]) -> String? {
        guard let state = redirectParams.first(where: { $0.name == "state"}) else {
            self.scopedKeySubject.onError(FxAError.RedirectNoState)
            return nil
        }

        guard let code = redirectParams.first(where: { $0.name == "code"}) else {
            self.scopedKeySubject.onError(FxAError.RedirectNoCode)
            return nil
        }

        if state.value == self.state {
            return code.value
        } else {
            self.scopedKeySubject.onError(FxAError.RedirectBadState)
            return nil
        }
    }

    private func postTokenRequest(code: String) {
        var request = URLRequest(url: tokenURL)
        let requestParams = [
            "grant_type": "authorization_code",
            "client_id": clientID,
            "code": code,
            "code_verifier": codeVerifier
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestParams)
        } catch {
            self.scopedKeySubject.onError(error)
            return
        }
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = session.dataTask(with: request) { data, response, error in
            if error != nil {
                self.scopedKeySubject.onError(error!)
                return
            }

            guard let data = data else {
                self.scopedKeySubject.onError(FxAError.EmptyOAuthData)
                return
            }

            var oauthInfo:OAuthInfo
            do {
                oauthInfo = try self.convertDataToOAuthInfo(data: data)
            } catch {
                self.scopedKeySubject.onError(error)
                return
            }

            self.scopedKeySubject.onNext(oauthInfo)
        }

        task.resume()
    }

    private func postProfileInfoRequest(code: String) {
        var request = URLRequest(url: profileInfoURL)
        request.httpMethod = "GET"
        request.addValue("Bearer", forHTTPHeaderField: "Authorization \(code)")

        let task = session.dataTask(with: request) { data, response, error in

        }

        task.resume()
    }

    private func convertDataToOAuthInfo(data: Data) throws -> OAuthInfo {
        let jsonData = try JSONSerialization.jsonObject(with: data)

        guard let jsonDict = jsonData as? [String:Any],
              let keysJWE = jsonDict["keys_jwe"] else {
            throw(FxAError.UnexpectedDataFormat)
        }

        let jweString = self.keyManager.decryptJWE(String(describing: keysJWE))
        let oauthInfo = try JSONDecoder().decode(OAuthInfo.self, from: Data(jweString.utf8))
        return oauthInfo
    }
}

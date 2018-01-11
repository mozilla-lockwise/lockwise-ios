/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

protocol FxAAction: Action { }

enum FxADisplayAction: FxAAction {
    case loadInitialURL(url:URL)
    case fetchingUserInformation
    case finishedFetchingUserInformation
}

extension FxADisplayAction: Equatable {
    static func ==(lhs:FxADisplayAction, rhs:FxADisplayAction) -> Bool {
        switch (lhs, rhs) {
            case (.loadInitialURL(let lhURL), .loadInitialURL(let rhURL)):
                return lhURL == rhURL
            case (.fetchingUserInformation, .fetchingUserInformation):
                return true
            case (.finishedFetchingUserInformation, .finishedFetchingUserInformation):
                return true
            default:
                return false
        }
    }
}

enum FxAInformationAction: FxAAction {
    case profileInfo(info:ProfileInfo)
    case oauthInfo(info:OAuthInfo)
    case scopedKey(key:String)
}

extension FxAInformationAction: Equatable {
    static func ==(lhs: FxAInformationAction, rhs: FxAInformationAction) -> Bool {
        switch (lhs, rhs) {
            case (.scopedKey(let lhKey), .scopedKey(let rhKey)):
                return lhKey == rhKey
            case (.profileInfo(let lhInfo), .profileInfo(let rhInfo)):
                return lhInfo == rhInfo
            case (.oauthInfo(let lhInfo), .oauthInfo(let rhInfo)):
                return lhInfo == rhInfo
            default:
                return false
        }
    }
}

class FxAActionHandler: ActionHandler {
    static let shared = FxAActionHandler()

    private var dispatcher: Dispatcher
    private var session: URLSession
    private var keyManager: KeyManager
    private let disposeBag = DisposeBag()

    lazy internal var oauthHost = "oauth-scoped-keys-oct10.dev.lcip.org"
    lazy internal var profileHost = "latest-keys.dev.lcip.org"
    lazy internal var clientID = "98adfa37698f255b"
    lazy internal var scope = "https://identity.mozilla.com/apps/lockbox"
    lazy internal var state: String = self.keyManager.random32()!.base64URLEncodedString()
    lazy internal var codeVerifier: String = self.keyManager.random32()!.base64URLEncodedString()
    lazy internal var jwkKey: String = self.keyManager.getEphemeralPublicECDH().base64URL()
    lazy internal var codeChallenge: String = self.codeVerifier.sha256withBase64URL()!

    lazy private var authURL: URL = { [weak self] in
        var components = URLComponents()

        components.scheme = "https"
        components.host = self?.oauthHost
        components.path = "/v1/authorization"

        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "access_type", value: "offline"),
            URLQueryItem(name: "client_id", value: self?.clientID),
            URLQueryItem(name: "redirect_uri", value: Constant.redirectURI),
            URLQueryItem(name: "scope", value: "profile:email openid \(self?.scope ?? "")"),
            URLQueryItem(name: "keys_jwk", value: self?.jwkKey),
            URLQueryItem(name: "state", value: self?.state),
            URLQueryItem(name: "code_challenge", value: self?.codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        return components.url!
    }()

    lazy private var tokenURL: URL = { [weak self] in
        var components = URLComponents()

        components.scheme = "https"
        components.host = self?.oauthHost
        components.path = "/v1/token"

        return components.url!
    }()

    lazy private var profileInfoURL: URL = { [weak self] in
        var components = URLComponents()
        components.scheme = "https"
        components.host = self?.profileHost
        components.path = "/v1/profile"

        return components.url!
    }()

    init(dispatcher: Dispatcher = Dispatcher.shared,
         session: URLSession = URLSession.shared,
         keyManager: KeyManager = KeyManager()) {
        self.dispatcher = dispatcher
        self.session = session
        self.keyManager = keyManager
    }

    public func initiateFxAAuthentication() {
        self.dispatcher.dispatch(action: FxADisplayAction.loadInitialURL(url: self.authURL))
    }

    public func matchingRedirectURLReceived(components: URLComponents) {
        var code:String
        do {
            code = try validateQueryParamsForAuthCode(components.queryItems!)
        } catch {
            self.dispatcher.dispatch(action: ErrorAction(error: error))
            return
        }

        self.dispatcher.dispatch(action: FxADisplayAction.fetchingUserInformation)
        self.authenticateAndRetrieveUserInformation(code: code)
    }
}

extension FxAActionHandler {
    private func authenticateAndRetrieveUserInformation(code: String) {
        self.postTokenRequest(code: code)
                .do(onNext: { info in
                    self.dispatcher.dispatch(action: FxAInformationAction.oauthInfo(info: info))
                    let scopedKey: String = try self.deriveScopedKeyFromJWE(info.keysJWE)
                    self.dispatcher.dispatch(action: FxAInformationAction.scopedKey(key: scopedKey))
                })
                .flatMap { info -> Single<ProfileInfo> in
                    self.postProfileInfoRequest(accessToken: info.accessToken)
                }
                .subscribe(onSuccess: { profileInfo in
                    self.dispatcher.dispatch(action: FxAInformationAction.profileInfo(info: profileInfo))
                    self.dispatcher.dispatch(action: FxADisplayAction.finishedFetchingUserInformation)
                }, onError: { err in
                    self.dispatcher.dispatch(action: ErrorAction(error: err))
                })
                .disposed(by: self.disposeBag)
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

// URL requests
extension FxAActionHandler {
    fileprivate func postTokenRequest(code: String) -> Single<OAuthInfo> {
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

    fileprivate func postProfileInfoRequest(accessToken: String) -> Single<ProfileInfo> {
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
}

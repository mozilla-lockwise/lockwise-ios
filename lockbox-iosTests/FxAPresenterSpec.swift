/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import WebKit

@testable import lockbox_ios

enum FxAPresenterSpecSharedExample : String {
    case PostProfileButDisplayError, DisplayDecodingError
}

class FxAPresenterSpec : QuickSpec {
    class FakeFxAView : FxAViewProtocol {
        var loadRequestArgument:URLRequest?
        var displayErrorArgument:Error?

        func loadRequest(_ urlRequest: URLRequest) {
            self.loadRequestArgument = urlRequest
        }

        func displayError(_ error:Error) -> Void {
            self.displayErrorArgument = error
        }
    }

    class FakeKeyManager : KeyManager {
        let fakeECDH = "fakeecdhissomuchstringyeshellohereweare"
        var fakeDecryptedJWE:String?
        var jweArgument:String?

        override func getEphemeralPublicECDH() -> String {
            return fakeECDH
        }

        override func decryptJWE(_ jwe: String) -> String {
            jweArgument = jwe
            return fakeDecryptedJWE!
        }
    }

    class FakeKeychainManager : KeychainManager {
        var userEmailArgument:String?
        var scopedKeyArgument:String?
        var uidArgument:String?

        @discardableResult
        override func saveUserEmail(_ email: String) -> Bool {
            userEmailArgument = email
            return true
        }

        @discardableResult
        override func saveScopedKey(_ key: String) -> Bool {
            scopedKeyArgument = key
            return true
        }

        @discardableResult
        override func saveFxAUID(_ uid: String) -> Bool {
            uidArgument = uid
            return true
        }
    }

    class FakeNavigationAction : WKNavigationAction {
        private var fakeRequest:URLRequest
        override var request:URLRequest {
            get {
                return self.fakeRequest
            }
        }

        init(request:URLRequest) {
            self.fakeRequest = request
        }
    }

    class FakeDataTask : URLSessionDataTask {
        var resumeCalled = false
        override func resume() {
            resumeCalled = true
        }
    }

    class FakeURLSession : URLSession {
        let dataTask = FakeDataTask()
        var dataTaskRequests:[String:URLRequest] = [:]
        var dataTaskCompletion:[String:((Data?, URLResponse?, Error?) -> Swift.Void)?] = [:]

        override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Swift.Void) -> URLSessionDataTask {
            let dictionaryKeyForRequest = request.url!.path
            self.dataTaskRequests[dictionaryKeyForRequest] = request
            self.dataTaskCompletion[dictionaryKeyForRequest] = completionHandler
            return dataTask
        }
    }

    var subject:FxAPresenter!
    var view:FakeFxAView!
    var session:FakeURLSession!
    var keyManager:FakeKeyManager!
    var keychainManager:FakeKeychainManager!

    override func spec() {
        sharedExamples(FxAPresenterSpecSharedExample.DisplayDecodingError.rawValue) {
            it("tells the view to display the error") {
                expect(self.view.displayErrorArgument).notTo(beNil())
                expect(self.view.displayErrorArgument).to(beAKindOf(DecodingError.self))
            }
        }

        describe("FxAPresenter") {
            beforeEach {
                self.view = FakeFxAView()
                self.session = FakeURLSession()
                self.keyManager = FakeKeyManager()
                self.keychainManager = FakeKeychainManager()
                self.subject = FxAPresenter(session: self.session, keyManager: self.keyManager, keychainManager: self.keychainManager)
                self.subject.view = self.view
            }

            describe(".onViewReady()") {
                beforeEach {
                    self.subject.onViewReady()
                }
                
                it("asks the view to load the initial oauth request with the appropriate parameters") {
                    expect(self.view.loadRequestArgument).notTo(beNil())

                    let components = URLComponents(url: self.view.loadRequestArgument!.url!, resolvingAgainstBaseURL: true)!
                    let queryItems = components.queryItems
                    
                    expect(components.scheme).to(equal("https"))
                    expect(components.host).to(equal(self.subject.oauthHost))
                    expect(queryItems).to(contain(URLQueryItem(name:"client_id", value:self.subject.clientID)))
                    expect(queryItems).to(contain(URLQueryItem(name:"keys_jwk", value:self.keyManager.fakeECDH.base64URL())))
                    expect(queryItems).to(contain(URLQueryItem(name:"state", value:self.subject.state)))
                    expect(queryItems).to(contain(URLQueryItem(name:"code_challenge", value:self.subject.codeVerifier.sha256withBase64URL())))
                    expect(queryItems).to(contain(URLQueryItem(name:"redirect_uri", value:self.subject.redirectURI)))
                }

                describe(".webViewRequest") {
                    var decisionHandler:((WKNavigationActionPolicy) -> Void)!
                    var returnedPolicy:WKNavigationActionPolicy?

                    beforeEach {
                        decisionHandler = { policy in
                            returnedPolicy = policy
                        }
                    }

                    describe("when called with a request URL that doesn't match the redirect URI") {
                        beforeEach {
                            let request = URLRequest(url: URL(string:"http://wwww.somefakewebsite.com")!)
                            self.subject.webViewRequest(decidePolicyFor: FakeNavigationAction(request:request), decisionHandler: decisionHandler)
                        }

                        it("allows the navigation action") {
                            expect(returnedPolicy!).to(equal(WKNavigationActionPolicy.allow))
                        }
                    }

                    describe("when called with a request URL matching the redirect URI") {
                        var urlComponents:URLComponents!

                        beforeEach {
                            urlComponents = URLComponents()
                            urlComponents.scheme = "lockbox"
                            urlComponents.host = "redirect.ios"
                        }

                        describe("when the redirect query items don't include the state parameter") {
                            beforeEach {
                                urlComponents.queryItems = [
                                    URLQueryItem(name: "code", value: "somecodevalueyep")
                                ]

                                let request = URLRequest(url: urlComponents.url!)
                                self.subject.webViewRequest(decidePolicyFor: FakeNavigationAction(request: request), decisionHandler: decisionHandler)
                            }

                            it("tells the view to display the no state error") {
                                expect(self.view.displayErrorArgument).notTo(beNil())
                                expect(self.view.displayErrorArgument).to(matchError(FxAError.RedirectNoState))
                            }
                        }

                        describe("when the redirect query items don't include the code parameter") {
                            beforeEach {
                                urlComponents.queryItems = [
                                    URLQueryItem(name: "state", value:  self.keyManager.random32()!.base64URLEncodedString())
                                ]

                                let request = URLRequest(url: urlComponents.url!)
                                self.subject.webViewRequest(decidePolicyFor: FakeNavigationAction(request: request), decisionHandler: decisionHandler)
                            }

                            it("tells the view to display the no code error") {
                                expect(self.view.displayErrorArgument).notTo(beNil())
                                expect(self.view.displayErrorArgument).to(matchError(FxAError.RedirectNoCode))
                            }
                        }

                        describe("when the redirect query items include the state parameter, but it doesn't match the passed state parameter") {
                            beforeEach {
                                urlComponents.queryItems = [
                                    URLQueryItem(name: "code", value: "somecodevalueyep"),
                                    URLQueryItem(name: "state", value: self.keyManager.random32()!.base64URLEncodedString())
                                ]

                                let request = URLRequest(url: urlComponents.url!)
                                self.subject.webViewRequest(decidePolicyFor: FakeNavigationAction(request: request), decisionHandler: decisionHandler)
                            }

                            it("tells the view to display the bad state error") {
                                expect(self.view.displayErrorArgument).notTo(beNil())
                                expect(self.view.displayErrorArgument).to(matchError(FxAError.RedirectBadState))
                            }
                        }

                        describe("when the redirect query items are in order & the state parameter matches the local state param") {
                            let code = "somethingthatfxawantsustohaverighthere"

                            beforeEach {
                                urlComponents.queryItems = [
                                    URLQueryItem(name: "code", value: code),
                                    URLQueryItem(name: "state", value: self.subject.state)
                                ]

                                let request = URLRequest(url: urlComponents.url!)
                                self.subject.webViewRequest(decidePolicyFor: FakeNavigationAction(request: request), decisionHandler: decisionHandler)
                            }

                            describe("the token request") {
                                let tokenPath = "/v1/token"

                                it("publishes a POST request for the token") {
                                    expect(self.session.dataTaskRequests[tokenPath]).toNot(beNil())
                                    let urlComponents = URLComponents(url: self.session.dataTaskRequests[tokenPath]!.url!, resolvingAgainstBaseURL: true)!

                                    let jsonData = try? JSONSerialization.jsonObject(with: self.session.dataTaskRequests[tokenPath]!.httpBody!) as? [String:String]
                                    expect(jsonData).notTo(beNil())

                                    expect(urlComponents.host).to(equal(self.subject.oauthHost))
                                    expect(jsonData!!["client_id"]).to(equal(self.subject.clientID))
                                    expect(jsonData!!["code"]).to(equal(code))
                                    expect(jsonData!!["code_verifier"]).to(equal(self.subject.codeVerifier))
                                }

                                describe("when receiving an error in the token data task callback") {
                                    let error = NSError(domain: "fxa-error", code: -1)

                                    beforeEach {
                                        self.session.dataTaskCompletion[tokenPath]!!(nil, nil, error)
                                    }

                                    it("tells the view to display the error") {
                                        expect(self.view.displayErrorArgument).notTo(beNil())
                                        expect(self.view.displayErrorArgument).to(matchError(error))
                                    }
                                }

                                describe("when receiving no error but an empty data value in the data task callback") {
                                    beforeEach {
                                        self.session.dataTaskCompletion[tokenPath]!!(nil, nil, nil)
                                    }

                                    it("tells the view to display the EmptyOAuthData error") {
                                        expect(self.view.displayErrorArgument).notTo(beNil())
                                        expect(self.view.displayErrorArgument).to(matchError(FxAError.EmptyOAuthData))
                                    }
                                }

                                describe("when receiving a data value in the data task callback") {
                                    describe("when the data value cannot be decoded to an OAuthInfo object") {
                                        let data = try! JSONSerialization.data(withJSONObject: ["meow": "something that doesn't look right"])

                                        beforeEach {
                                            self.session.dataTaskCompletion[tokenPath]!!(data, nil, nil)
                                        }

                                        itBehavesLike(FxAPresenterSpecSharedExample.DisplayDecodingError.rawValue)
                                    }

                                    describe("when the data value can be decoded to an OAuthInfo object") {
                                        let keysJWE = "somekeyvaluehere"
                                        let accessToken = "beareraccesstoken"
                                        let oauthInfo = OAuthInfo.Builder()
                                                .keysJWE(keysJWE)
                                                .accessToken(accessToken)
                                                .build()
                                        let oauthData = try! JSONEncoder().encode(oauthInfo)
                                        let profilePath = "/v1/profile"

                                        sharedExamples(FxAPresenterSpecSharedExample.PostProfileButDisplayError.rawValue) {
                                            it("posts the bearer access token to the profiles endpoint") {
                                                expect(self.session.dataTaskRequests[profilePath]).notTo(beNil())
                                                let urlComponents = URLComponents(url: self.session.dataTaskRequests[profilePath]!.url!, resolvingAgainstBaseURL: true)!

                                                expect(urlComponents.host).to(equal(self.subject.profileHost))
                                            }

                                            it("tells the view to display the UnexpectedDataFormat error") {
                                                expect(self.view.displayErrorArgument).notTo(beNil())
                                                expect(self.view.displayErrorArgument).to(matchError(FxAError.UnexpectedDataFormat))
                                            }
                                        }

                                        describe("when the keysJWE value cannot be deserialized to the expected dictionary format") {
                                            beforeEach {
                                                self.keyManager.fakeDecryptedJWE = "[\"bogus\"]"
                                                self.session.dataTaskCompletion[tokenPath]!!(oauthData, nil, nil)
                                            }

                                            itBehavesLike(FxAPresenterSpecSharedExample.PostProfileButDisplayError.rawValue)
                                        }

                                        describe("when the keysJWE value can be deserialized to the expected dictionary format") {
                                            describe("when the decrypted & deserialized keysJWE value does not have a key for the scope") {
                                                beforeEach {
                                                    self.keyManager.fakeDecryptedJWE = "{\"somenonesensekey\":{\"wrongthingsinhere\":\"yep\"}}"
                                                    self.session.dataTaskCompletion[tokenPath]!!(oauthData, nil, nil)
                                                }

                                                itBehavesLike(FxAPresenterSpecSharedExample.PostProfileButDisplayError.rawValue)
                                            }

                                            describe("when the decrypted & deserialized keysJWE value has a key for the scope") {
                                                describe("when the value for the scope does not have a key 'k'") {
                                                    beforeEach {
                                                        self.keyManager.fakeDecryptedJWE = "{\"\(self.subject.scope)\":{\"incomplete\":\"sorry\"}}"
                                                        self.session.dataTaskCompletion[tokenPath]!!(oauthData, nil, nil)
                                                    }

                                                    itBehavesLike(FxAPresenterSpecSharedExample.PostProfileButDisplayError.rawValue)
                                                }

                                                describe("when the value for the scope has a key 'k'") {
                                                    let scopedKey = "allwecareaboutanyway"
                                                    beforeEach {
                                                        self.keyManager.fakeDecryptedJWE = "{\"\(self.subject.scope)\":{\"k\":\"\(scopedKey)\"}}"
                                                        self.session.dataTaskCompletion[tokenPath]!!(oauthData, nil, nil)
                                                    }

                                                    it("posts the bearer access token to the profiles endpoint") {
                                                        expect(self.session.dataTaskRequests[profilePath]).notTo(beNil())
                                                        let urlComponents = URLComponents(url: self.session.dataTaskRequests[profilePath]!.url!, resolvingAgainstBaseURL: true)!

                                                        expect(urlComponents.host).to(equal(self.subject.profileHost))
                                                    }

                                                    it("saves the key to the keychain") {
                                                        expect(self.keychainManager.scopedKeyArgument).notTo(beNil())
                                                        expect(self.keychainManager.scopedKeyArgument).to(equal(scopedKey))
                                                    }
                                                }
                                            }

                                            describe("the profile request") {
                                                beforeEach {
                                                    self.keyManager.fakeDecryptedJWE = "{\"\(self.subject.scope)\":{\"k\":\"fakekeyvalue\"}}"
                                                    self.session.dataTaskCompletion[tokenPath]!!(oauthData, nil, nil)
                                                }

                                                describe("when receiving an error in the profile data task callback") {
                                                    let error = NSError(domain: "fxa-error", code: -1)

                                                    beforeEach {
                                                        self.session.dataTaskCompletion[profilePath]!!(nil, nil, error)
                                                    }

                                                    it("tells the view to display the error") {
                                                        expect(self.view.displayErrorArgument).notTo(beNil())
                                                        expect(self.view.displayErrorArgument).to(matchError(error))
                                                    }
                                                }

                                                describe("when receiving no error but an empty data value in the data task callback") {
                                                    beforeEach {
                                                        self.session.dataTaskCompletion[profilePath]!!(nil, nil, nil)
                                                    }

                                                    it("tells the view to display the EmptyOAuthData error") {
                                                        expect(self.view.displayErrorArgument).notTo(beNil())
                                                        expect(self.view.displayErrorArgument).to(matchError(FxAError.EmptyProfileInfoData))
                                                    }
                                                }

                                                describe("when receiving data in the data task callback") {
                                                    describe("when receiving an invalid ProfileInfo encoding") {
                                                        let profileData = try! JSONSerialization.data(withJSONObject: ["meow": "something that doesn't look right"])
                                                        beforeEach {
                                                            self.session.dataTaskCompletion[profilePath]!!(profileData, nil, nil)
                                                        }

                                                        itBehavesLike(FxAPresenterSpecSharedExample.DisplayDecodingError.rawValue)
                                                    }

                                                    describe("when receiving a valid ProfileInfo encoding") {
                                                        let email = "butts@butts.com"
                                                        let uid = "534785348945089"
                                                        let profileInfo = ProfileInfo.Builder()
                                                                .email(email)
                                                                .uid(uid)
                                                                .build()
                                                        let profileData = try! JSONEncoder().encode(profileInfo)

                                                        beforeEach {
                                                            self.session.dataTaskCompletion[profilePath]!!(profileData, nil, nil)
                                                        }

                                                        it("saves the email to the keychain") {
                                                            expect(self.keychainManager.userEmailArgument).notTo(beNil())
                                                            expect(self.keychainManager.userEmailArgument).to(equal(email))
                                                        }

                                                        it("saves the uid to the keychain") {
                                                            expect(self.keychainManager.uidArgument).notTo(beNil())
                                                            expect(self.keychainManager.uidArgument).to(equal(uid))
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

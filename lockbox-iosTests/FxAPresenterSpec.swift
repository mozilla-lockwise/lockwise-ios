/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import RxSwift
import RxTest
import WebKit

@testable import lockbox_ios

class FxAPresenterSpec : QuickSpec {
    class FakeFxAView : FxAViewProtocol {
        var loadRequestCalled = false
        var loadRequestArgument:URLRequest?
        func loadRequest(_ urlRequest: URLRequest) {
            self.loadRequestCalled = true
            self.loadRequestArgument = urlRequest
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

    class FakeDataTask : URLSessionDataTask { }

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

    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()

    override func spec() {
        describe("FxAPresenter") {
            beforeEach {
                self.view = FakeFxAView()
                self.session = FakeURLSession()
                self.keyManager = FakeKeyManager()
                self.subject = FxAPresenter(session: self.session, keyManager: self.keyManager)
                self.subject.view = self.view
            }

            describe(".authenticateAndRetrieveScopedKey") {
                var oauthObserver = self.scheduler.createObserver(OAuthInfo.self)

                beforeEach {
                    oauthObserver = self.scheduler.createObserver(OAuthInfo.self)
                    self.subject.authenticateAndRetrieveScopedKey()
                            .asObservable()
                            .subscribe(oauthObserver)
                            .disposed(by: self.disposeBag)
                }

                it("asks the view to load the initial oauth request with the appropriate parameters") {
                    expect(self.view.loadRequestCalled).to(beTrue())

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

                            it("pushes the no state error to the observable") {
                                expect(oauthObserver.events.first!.value.error).to(matchError(FxAError.RedirectNoState))
                                expect(oauthObserver.events.first!.value.element).to(beNil())
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

                            it("pushes the no code error to the observable") {
                                expect(oauthObserver.events.first!.value.error).to(matchError(FxAError.RedirectNoCode))
                                expect(oauthObserver.events.first!.value.element).to(beNil())
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

                            it("pushes the bad state error to the observable") {
                                expect(oauthObserver.events.first!.value.error).to(matchError(FxAError.RedirectBadState))
                                expect(oauthObserver.events.first!.value.element).to(beNil())
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
                                    expect(self.session.dataTaskRequests).toNot(beNil())
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

                                    it("pushes the error to the observer") {
                                        expect(oauthObserver.events.first!.value.error).to(matchError(error))
                                        expect(oauthObserver.events.first!.value.element).to(beNil())
                                    }
                                }

                                describe("when receiving no error but an empty data value in the data task callback") {
                                    beforeEach {
                                        self.session.dataTaskCompletion[tokenPath]!!(nil, nil, nil)
                                    }

                                    it("pushes the EmptyOAuthDatta error to the observer") {
                                        expect(oauthObserver.events.first!.value.error).to(matchError(FxAError.EmptyOAuthData))
                                        expect(oauthObserver.events.first!.value.element).to(beNil())
                                    }
                                }

                                describe("when receiving a data value in the data task callback") {
                                    describe("when the data value does not serialize to a dictionary") {
                                        beforeEach {
                                            let data = try! JSONSerialization.data(withJSONObject: ["smurf"])
                                            self.session.dataTaskCompletion[tokenPath]!!(data, nil, nil)
                                        }

                                        it("pushes the EmptyOAuthDatta error to the observer") {
                                            expect(oauthObserver.events.first!.value.error).to(matchError(FxAError.UnexpectedDataFormat))
                                            expect(oauthObserver.events.first!.value.element).to(beNil())
                                        }
                                    }

                                    describe("when the data value serializes to a dictionary but does not have the keys_jwe key") {

                                        describe("when the dictionary does not have the keys_jwe key") {
                                            beforeEach {
                                                let data = try! JSONSerialization.data(withJSONObject: ["blah":"yes"])
                                                self.session.dataTaskCompletion[tokenPath]!!(data, nil, nil)
                                            }

                                            it("pushes the EmptyOAuthData error to the observer") {
                                                expect(oauthObserver.events.first!.value.error).to(matchError(FxAError.UnexpectedDataFormat))
                                                expect(oauthObserver.events.first!.value.element).to(beNil())
                                            }
                                        }

                                        describe("when the dictionary has the keys_jwe key") {
                                            let keysJWEValue = "[{\"somelongencodedstringhere\":\"murf\"}]"
                                            let data = try! JSONSerialization.data(withJSONObject: ["keys_jwe":keysJWEValue])

                                            // note: populate values when server is testable
                                            xdescribe("when the decrypted value does not correspnd with the oauthinfo object") {
                                                beforeEach {
                                                    self.keyManager.fakeDecryptedJWE = "bogus"
                                                    self.session.dataTaskCompletion[tokenPath]!!(data, nil, nil)
                                                }

                                                it("passes the keys_jwe value to the key manager") {
                                                    expect(self.keyManager.jweArgument).to(equal(keysJWEValue))
                                                }

                                                it("pushes the decoder error to the observer") {
                                                    expect(oauthObserver.events.first!.value.error).to(beNil())
                                                    expect(oauthObserver.events.first!.value.element).to(beNil())
                                                }
                                            }

                                            xdescribe("when the decrypted value corresponds with the oauthinfo object") {
                                                beforeEach {
                                                    self.keyManager.fakeDecryptedJWE = "real"
                                                    self.session.dataTaskCompletion[tokenPath]!!(data, nil, nil)
                                                }

                                                it("passes the keys_jwe value to the key manager") {
                                                    expect(self.keyManager.jweArgument).to(equal(keysJWEValue))
                                                }

                                                it("pushes the oauthinfo value to the observer") {

                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            describe("the profile info request") {
                                let profilePath = "/v1/profile"

                                it("publishes a GET request for the profile info") {
                                    expect(self.session.dataTaskRequests).toNot(beNil())
                                    let urlComponents = URLComponents(url: self.session.dataTaskRequests[profilePath]!.url!, resolvingAgainstBaseURL: true)!

                                    expect(urlComponents.host).to(equal(self.subject.profileHost))
                                }

                                describe("when receiving an error in the token data task callback") {
                                    let error = NSError(domain: "fxa-error", code: -1)

                                    beforeEach {
                                        self.session.dataTaskCompletion[profilePath]!!(nil, nil, error)
                                    }

                                    it("pushes the error to the observer") {
                                        expect(oauthObserver.events.first!.value.error).to(matchError(error))
                                        expect(oauthObserver.events.first!.value.element).to(beNil())
                                    }
                                }

                                describe("when receiving no error but an empty data value in the data task callback") {
                                    beforeEach {
                                        self.session.dataTaskCompletion[profilePath]!!(nil, nil, nil)
                                    }

                                    it("pushes the EmptyOAuthData error to the observer") {
                                        expect(oauthObserver.events.first!.value.error).to(matchError(FxAError.EmptyOAuthData))
                                        expect(oauthObserver.events.first!.value.element).to(beNil())
                                    }
                                }

                                describe("when receiving a data value in the data task callback") {
                                    describe("when the data value does not serialize to a dictionary") {
                                        beforeEach {
                                            let data = try! JSONSerialization.data(withJSONObject: ["smurf"])
                                            self.session.dataTaskCompletion[profilePath]!!(data, nil, nil)
                                        }

                                        it("pushes the EmptyOAuthDatta error to the observer") {
                                            expect(oauthObserver.events.first!.value.error).to(matchError(FxAError.UnexpectedDataFormat))
                                            expect(oauthObserver.events.first!.value.element).to(beNil())
                                        }
                                    }

                                    describe("when the data value serializes to a dictionary but does not have the keys_jwe key") {

                                        describe("when the dictionary does not have the keys_jwe key") {
                                            beforeEach {
                                                let data = try! JSONSerialization.data(withJSONObject: ["blah":"yes"])
                                                self.session.dataTaskCompletion[profilePath]!!(data, nil, nil)
                                            }

                                            it("pushes the EmptyOAuthData error to the observer") {
                                                expect(oauthObserver.events.first!.value.error).to(matchError(FxAError.UnexpectedDataFormat))
                                                expect(oauthObserver.events.first!.value.element).to(beNil())
                                            }
                                        }

                                        describe("when the dictionary has the keys_jwe key") {
                                            let keysJWEValue = "[{\"somelongencodedstringhere\":\"murf\"}]"
                                            let data = try! JSONSerialization.data(withJSONObject: ["keys_jwe":keysJWEValue])

                                            // note: populate values when server is testable
                                            xdescribe("when the decrypted value does not correspnd with the oauthinfo object") {
                                                beforeEach {
                                                    self.keyManager.fakeDecryptedJWE = "bogus"
                                                    self.session.dataTaskCompletion[profilePath]!!(data, nil, nil)
                                                }

                                                it("passes the keys_jwe value to the key manager") {
                                                    expect(self.keyManager.jweArgument).to(equal(keysJWEValue))
                                                }

                                                it("pushes the decoder error to the observer") {
                                                    expect(oauthObserver.events.first!.value.error).to(beNil())
                                                    expect(oauthObserver.events.first!.value.element).to(beNil())
                                                }
                                            }

                                            xdescribe("when the decrypted value corresponds with the oauthinfo object") {
                                                beforeEach {
                                                    self.keyManager.fakeDecryptedJWE = "real"
                                                    self.session.dataTaskCompletion[profilePath]!!(data, nil, nil)
                                                }

                                                it("passes the keys_jwe value to the key manager") {
                                                    expect(self.keyManager.jweArgument).to(equal(keysJWEValue))
                                                }

                                                it("pushes the oauthinfo value to the observer") {

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

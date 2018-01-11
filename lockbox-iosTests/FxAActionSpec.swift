/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble

@testable import lockbox_ios

enum FxAActionSpecSharedExample : String {
    case DispatchDecodingError, PostOAuthInfoButDispatchError
}

class FxAActionSpec : QuickSpec {
    class FakeDispatcher : Dispatcher {
        var actionArguments: [Action] = []

        override func dispatch(action: Action) {
            self.actionArguments.append(action)
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

    private var keyManager:FakeKeyManager!
    private var session:FakeURLSession!
    private var dispatcher:FakeDispatcher!
    var subject:FxAActionHandler!

    override func spec() {
        describe("FxAActionHandler") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.keyManager = FakeKeyManager()
                self.session = FakeURLSession()

                self.subject = FxAActionHandler(dispatcher: self.dispatcher, session: self.session, keyManager: self.keyManager)
            }

            describe(".initiateFxAAuthentication") {
                beforeEach {
                    self.subject.initiateFxAAuthentication()
                }

                it("dispatches the loadURL display action") {
                    var components = URLComponents()

                    components.scheme = "https"
                    components.host = self.subject.oauthHost
                    components.path = "/v1/authorization"

                    components.queryItems = [
                        URLQueryItem(name: "response_type", value: "code"),
                        URLQueryItem(name: "access_type", value: "offline"),
                        URLQueryItem(name: "client_id", value: self.subject.clientID),
                        URLQueryItem(name: "redirect_uri", value: Constant.redirectURI),
                        URLQueryItem(name: "scope", value: "profile:email openid \(self.subject.scope)"),
                        URLQueryItem(name: "keys_jwk", value: self.subject.jwkKey),
                        URLQueryItem(name: "state", value: self.subject.state),
                        URLQueryItem(name: "code_challenge", value: self.subject.codeChallenge),
                        URLQueryItem(name: "code_challenge_method", value: "S256")
                    ]

                    let displayAction = self.dispatcher.actionArguments.popLast() as! FxADisplayAction
                    expect(displayAction).to(equal(FxADisplayAction.loadInitialURL(url: components.url!)))
                }
            }

            describe(".matchingRedirectURLReceived()") {
                var urlComponents:URLComponents!

                beforeEach {
                    urlComponents = URLComponents()
                    urlComponents.scheme = "lockbox"
                    urlComponents.host = "redirect.ios"
                }

                sharedExamples(FxAActionSpecSharedExample.DispatchDecodingError.rawValue) {
                    it("dispatches the error") {
                        let argument = self.dispatcher.actionArguments.last as! ErrorAction
                        expect(argument.error).to(beAKindOf(DecodingError.self))
                    }
                }

                describe("when the redirect query items don't include the state parameter") {
                    beforeEach {
                        urlComponents.queryItems = [
                            URLQueryItem(name: "code", value: "somecodevalueyep")
                        ]

                        self.subject.matchingRedirectURLReceived(components: urlComponents)
                    }

                    it("dispatches the no state error") {
                        expect(self.dispatcher.actionArguments).notTo(beEmpty())
                        let argument = self.dispatcher.actionArguments.first as! ErrorAction
                        expect(argument).to(matchErrorAction(ErrorAction(error: FxAError.RedirectNoState)))
                    }
                }

                describe("when the redirect query items don't include the code parameter") {
                    beforeEach {
                        urlComponents.queryItems = [
                            URLQueryItem(name: "state", value: self.keyManager.random32()!.base64URLEncodedString())
                        ]

                        self.subject.matchingRedirectURLReceived(components: urlComponents)
                    }

                    it("dispatches the no code error") {
                        expect(self.dispatcher.actionArguments).notTo(beEmpty())
                        let argument = self.dispatcher.actionArguments.first as! ErrorAction
                        expect(argument).to(matchErrorAction(ErrorAction(error: FxAError.RedirectNoCode)))
                    }
                }

                describe("when the redirect query items include the state parameter, but it doesn't match the passed state parameter") {
                    beforeEach {
                        urlComponents.queryItems = [
                            URLQueryItem(name: "code", value: "somecodevalueyep"),
                            URLQueryItem(name: "state", value: self.keyManager.random32()!.base64URLEncodedString())
                        ]

                        self.subject.matchingRedirectURLReceived(components: urlComponents)
                    }

                    it("dispatches the bad state error") {
                        expect(self.dispatcher.actionArguments).notTo(beEmpty())
                        let argument = self.dispatcher.actionArguments.first as! ErrorAction
                        expect(argument).to(matchErrorAction(ErrorAction(error: FxAError.RedirectBadState)))
                    }
                }

                describe("when the redirect query items are in order & the state parameter matches the local state param") {
                    let code = "somethingthatfxawantsustohaverighthere"

                    beforeEach {
                        urlComponents.queryItems = [
                            URLQueryItem(name: "code", value: code),
                            URLQueryItem(name: "state", value: self.subject.state)
                        ]

                        self.subject.matchingRedirectURLReceived(components: urlComponents)
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

                            it("dispatches the error") {
                                let argument = self.dispatcher.actionArguments.last as! ErrorAction
                                expect(argument).to(matchErrorAction(ErrorAction(error: error)))
                            }
                        }

                        describe("when receiving no error but an empty data value in the data task callback") {
                            beforeEach {
                                self.session.dataTaskCompletion[tokenPath]!!(nil, nil, nil)
                            }

                            it("dispatches the bad state error") {
                                let argument = self.dispatcher.actionArguments.last as! ErrorAction
                                expect(argument).to(matchErrorAction(ErrorAction(error: FxAError.EmptyOAuthData)))
                            }
                        }

                        describe("when receiving a data value in the data task callback") {
                            describe("when the data value cannot be decoded to an OAuthInfo object") {
                                let data = try! JSONSerialization.data(withJSONObject: ["meow": "something that doesn't look right"])

                                beforeEach {
                                    self.session.dataTaskCompletion[tokenPath]!!(data, nil, nil)
                                }

                                itBehavesLike(FxAActionSpecSharedExample.DispatchDecodingError.rawValue)
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

                                sharedExamples(FxAActionSpecSharedExample.PostOAuthInfoButDispatchError.rawValue) {
                                    it("posts the oauthInfo to the dispatcher & dispatches an error") {
                                        let errorArgument = self.dispatcher.actionArguments.popLast() as! ErrorAction
                                        expect(errorArgument).to(matchErrorAction(ErrorAction(error: FxAError.UnexpectedDataFormat)))

                                        let argument = self.dispatcher.actionArguments.popLast() as! FxAInformationAction
                                        expect(argument).to(equal(FxAInformationAction.oauthInfo(info: oauthInfo)))
                                    }
                                }

                                describe("when the keysJWE value cannot be deserialized to the expected dictionary format") {
                                    beforeEach {
                                        self.keyManager.fakeDecryptedJWE = "[\"bogus\"]"
                                        self.session.dataTaskCompletion[tokenPath]!!(oauthData, nil, nil)
                                    }

                                    itBehavesLike(FxAActionSpecSharedExample.PostOAuthInfoButDispatchError.rawValue)
                                }

                                describe("when the keysJWE value can be deserialized to the expected dictionary format") {
                                    describe("when the decrypted & deserialized keysJWE value does not have a key for the scope") {
                                        beforeEach {
                                            self.keyManager.fakeDecryptedJWE = "{\"somenonesensekey\":{\"wrongthingsinhere\":\"yep\"}}"
                                            self.session.dataTaskCompletion[tokenPath]!!(oauthData, nil, nil)
                                        }

                                        itBehavesLike(FxAActionSpecSharedExample.PostOAuthInfoButDispatchError.rawValue)
                                    }

                                    describe("when the decrypted & deserialized keysJWE value has a key for the scope") {
                                        describe("when the value for the scope does not have a key 'k'") {
                                            beforeEach {
                                                self.keyManager.fakeDecryptedJWE = "{\"\(self.subject.scope)\":{\"incomplete\":\"sorry\"}}"
                                                self.session.dataTaskCompletion[tokenPath]!!(oauthData, nil, nil)
                                            }

                                            itBehavesLike(FxAActionSpecSharedExample.PostOAuthInfoButDispatchError.rawValue)
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

                                            it("dispatches the scoped key to the dispatcher") {
                                                let argument = self.dispatcher.actionArguments.last as! FxAInformationAction
                                                expect(argument).to(equal(FxAInformationAction.scopedKey(key: scopedKey)))
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

                                            it("dispatches the error") {
                                                let argument = self.dispatcher.actionArguments.last as! ErrorAction
                                                expect(argument).to(matchErrorAction(ErrorAction(error: error)))
                                            }
                                        }

                                        describe("when receiving no error but an empty data value in the data task callback") {
                                            beforeEach {
                                                self.session.dataTaskCompletion[profilePath]!!(nil, nil, nil)
                                            }

                                            it("dispatches the EmptyOAuthData error") {
                                                let argument = self.dispatcher.actionArguments.last as! ErrorAction
                                                expect(argument).to(matchErrorAction(ErrorAction(error: FxAError.EmptyProfileInfoData)))
                                            }
                                        }

                                        describe("when receiving data in the data task callback") {
                                            describe("when receiving an invalid ProfileInfo encoding") {
                                                let profileData = try! JSONSerialization.data(withJSONObject: ["meow": "something that doesn't look right"])
                                                beforeEach {
                                                    self.session.dataTaskCompletion[profilePath]!!(profileData, nil, nil)
                                                }

                                                itBehavesLike(FxAActionSpecSharedExample.DispatchDecodingError.rawValue)
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

                                                it("dispatches the profileinfo object & updates the request status") {
                                                    let displayArgument = self.dispatcher.actionArguments.popLast() as! FxADisplayAction
                                                    expect(displayArgument).to(equal(FxADisplayAction.finishedFetchingUserInformation))

                                                    let infoArgument = self.dispatcher.actionArguments.popLast() as! FxAInformationAction
                                                    expect(infoArgument).to(equal(FxAInformationAction.profileInfo(info: profileInfo)))
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

        describe("FxAInformationAction") {
            describe("equality") {
                it("profileInfo is equal when the infos are equal") {
                    let profileInfo = ProfileInfo.Builder().build()
                    expect(FxAInformationAction.profileInfo(info: profileInfo)).to(equal(FxAInformationAction.profileInfo(info: profileInfo)))
                }

                it("profileInfo is not equal when the infos are not equal") {
                    let profileInfo = ProfileInfo.Builder().build()
                    let secondProfileInfo = ProfileInfo.Builder().uid("jafdslkjfsdlj").build()
                    expect(FxAInformationAction.profileInfo(info: profileInfo)).notTo(equal(FxAInformationAction.profileInfo(info: secondProfileInfo)))
                }

                it("oauthInfo is equal when the infos are equal") {
                    let oauthInfo = OAuthInfo.Builder().build()
                    expect(FxAInformationAction.oauthInfo(info: oauthInfo)).to(equal(FxAInformationAction.oauthInfo(info: oauthInfo)))
                }

                it("oauthInfo is not equal when the infos are not equal") {
                    let oauthInfo = OAuthInfo.Builder().build()
                    let secondOauthInfo = OAuthInfo.Builder().idToken("fsdjksfdljkds").build()
                    expect(FxAInformationAction.oauthInfo(info: oauthInfo)).notTo(equal(FxAInformationAction.oauthInfo(info: secondOauthInfo)))
                }

                it("scopedKey is equal when the infos are equal") {
                    let key = "a key!"
                    expect(FxAInformationAction.scopedKey(key: key)).to(equal(FxAInformationAction.scopedKey(key: key)))
                }

                it("scopedKey is not equal when the infos are not equal") {
                    expect(FxAInformationAction.scopedKey(key: "woof")).notTo(equal(FxAInformationAction.scopedKey(key: "meow")))

                }
                it("different enum values are never equal") {
                    expect(FxAInformationAction.oauthInfo(info: OAuthInfo.Builder().build())).notTo(equal(FxAInformationAction.profileInfo(info: ProfileInfo.Builder().build())))
                    expect(FxAInformationAction.scopedKey(key: "blah")).notTo(equal(FxAInformationAction.profileInfo(info: ProfileInfo.Builder().build())))
                    expect(FxAInformationAction.oauthInfo(info: OAuthInfo.Builder().build())).notTo(equal(FxAInformationAction.scopedKey(key: "a key here!")))
                }
            }
        }

        describe("FxADisplayAction") {
            describe("equality") {
                it("loadInitialURL is equal when the urls are equal") {
                    let someURL = URL(string: "www.butts.com")!
                    expect(FxADisplayAction.loadInitialURL(url: someURL)).to(equal(FxADisplayAction.loadInitialURL(url: someURL)))
                }

                it("loadInitialURL is not equal when the urls are not equal") {
                    let someURL = URL(string: "www.butts.com")!
                    let someOtherURL = URL(string: "www.mozilla.org")!
                    expect(FxADisplayAction.loadInitialURL(url: someURL)).notTo(equal(FxADisplayAction.loadInitialURL(url: someOtherURL)))
                }

                it("fetchingUserInformation is always equal") {
                    expect(FxADisplayAction.fetchingUserInformation).to(equal(FxADisplayAction.fetchingUserInformation))
                }

                it("loadInitialURL is always equal") {
                    expect(FxADisplayAction.finishedFetchingUserInformation).to(equal(FxADisplayAction.finishedFetchingUserInformation))
                }

                it("different enum values are never equal") {
                    expect(FxADisplayAction.fetchingUserInformation).notTo(equal(FxADisplayAction.finishedFetchingUserInformation))
                    expect(FxADisplayAction.finishedFetchingUserInformation).notTo(equal(FxADisplayAction.loadInitialURL(url: URL(string: "www.butts.com")!)))
                }
            }
        }
    }
}
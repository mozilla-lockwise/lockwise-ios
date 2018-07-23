/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import RxSwift
import RxTest
import RxBlocking
import FxAClient
import SwiftKeychainWrapper

@testable import Lockbox

class AccountStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    class FakeKeychainManager: KeychainWrapper {
        var saveArguments: [String: String] = [:]
        var saveSuccess: Bool!
        var retrieveResult: [String: String] = [:]
        var removeArguments: [String] = []

        override func set(_ value: String, forKey key: String, withAccessibility accessibility: SwiftKeychainWrapper.KeychainItemAccessibility? = nil) -> Bool {
            self.saveArguments[key] = value
            return saveSuccess
        }

        override func string(forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> String? {
            return retrieveResult[key]
        }

        override func removeObject(forKey key: String, withAccessibility accessibility: KeychainItemAccessibility?) -> Bool {
            self.removeArguments.append(key)
            return true
        }

        init() { super.init(serviceName: "blah") }
    }

    private var dispatcher: FakeDispatcher!
    private var keychainManager: FakeKeychainManager!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: AccountStore!

    override func spec() {
        describe("AccountStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.keychainManager = FakeKeychainManager()
                self.subject = AccountStore(
                        dispatcher: self.dispatcher,
                        keychainWrapper: self.keychainManager
                )
            }

            describe("loginURL") {
                var urlObserver = self.scheduler.createObserver(URL.self)

                beforeEach {
                    urlObserver = self.scheduler.createObserver(URL.self)

                    self.subject.loginURL
                            .bind(to: urlObserver)
                            .disposed(by: self.disposeBag)
                }

                it("populates the loginURL for the Lockbox configuration on initialization") {
                    FxAConfig.custom(content_base: "https://accounts.firefox.com") { config, error in
                        guard let config = config else { return }

                        let fxa = try? FirefoxAccount(config: config, clientId: Constant.fxa.clientID, redirectUri: Constant.fxa.redirectURI)
                        fxa?.beginOAuthFlow(scopes: Constant.fxa.scopes, wantsKeys: true) { url, _ in
                            expect(urlObserver.events.first!.value.element!.path).to(equal(url!.path))
                        }

                    }
                }
            }

            describe("profile") {
                describe("when the keychain has a valid fxa account") {
                    beforeEach {
                        self.keychainManager.retrieveResult[KeychainKey.accountJSON.rawValue] = "{\"schema_version\":\"V1\",\"client_id\":\"98adfa37698f255b\",\"config\":{\"content_url\":\"https://accounts.firefox.com\",\"auth_url\":\"https://api.accounts.firefox.com/\",\"oauth_url\":\"https://oauth.accounts.firefox.com/\",\"profile_url\":\"https://profile.accounts.firefox.com/\",\"token_server_endpoint_url\":\"https://token.services.mozilla.com/1.0/sync/1.5\",\"authorization_endpoint\":\"https://accounts.firefox.com/authorization\",\"issuer\":\"https://accounts.firefox.com\",\"jwks_uri\":\"https://oauth.accounts.firefox.com/v1/jwks\",\"token_endpoint\":\"https://oauth.accounts.firefox.com/v1/token\",\"userinfo_endpoint\":\"https://profile.accounts.firefox.com/v1/profile\"},\"login_state\":\"Unknown\",\"oauth_cache\":{\"profile https://identity.mozilla.com/apps/oldsync https://identity.mozilla.com/apps/lockbox\":{\"access_token\":\"42e4bacc8affd23a4ae264fd59ae8ec4a58d5af03b1215daa9cd940f6f80bd9e\",\"keys\":\"{\\\"https://identity.mozilla.com/apps/oldsync\\\":{\\\"kty\\\":\\\"oct\\\",\\\"scope\\\":\\\"https://identity.mozilla.com/apps/oldsync\\\",\\\"k\\\":\\\"VEZDYJ3Jd1Ui0ZVtW8pPHD6LZ48Jd30p-y-PLQQYa0PRcMZtiM6zJO4_I2lxEg__qkxXldPyLiM5PYY9VBD64w\\\",\\\"kid\\\":\\\"1519160140602-WMF1HOhJbtMVueuy3tV4vA\\\"},\\\"https://identity.mozilla.com/apps/lockbox\\\":{\\\"kty\\\":\\\"oct\\\",\\\"scope\\\":\\\"https://identity.mozilla.com/apps/lockbox\\\",\\\"k\\\":\\\"oGGfsZk8xMXtBzGzy2WY3QGPNOTer0VGIC3Uyz9Jy9w\\\",\\\"kid\\\":\\\"1519160141-YqmShzWPQhHp0RNiZs25zg\\\"}}\",\"refresh_token\":\"fd417de6f90683a046070450ead9844a095bee5df934cc0fe3455bd2d41d394a\",\"expires_at\":1531864458,\"scopes\":[\"profile\",\"https://identity.mozilla.com/apps/oldsync\",\"https://identity.mozilla.com/apps/lockbox\"]}}}"

                        self.subject = AccountStore(
                                dispatcher: self.dispatcher,
                                keychainWrapper: self.keychainManager
                        )

                    }

                    xit("pushes a non-nil profile") {
                        // can't check anything more detailed because we can't construct FxAClient.Profile
                        let profile = try? self.subject.profile.toBlocking().first()
                        expect(profile).notTo(beNil())
                    }
                }

                describe("when the keychain does not have a valid fxa account") {
                    beforeEach {
                        self.subject = AccountStore(
                                dispatcher: self.dispatcher,
                                keychainWrapper: self.keychainManager
                        )
                    }

                    it("pushes a nil profile") {
                        let profile = try? self.subject.profile.toBlocking().first()
                        expect(profile).to(beNil())
                    }
                }
            }

            describe("oauthInfo") {
                describe("when the keychain has a valid fxa account") {
                    beforeEach {
                        self.keychainManager.retrieveResult[KeychainKey.accountJSON.rawValue] = "{\"schema_version\":\"V1\",\"client_id\":\"98adfa37698f255b\",\"config\":{\"content_url\":\"https://accounts.firefox.com\",\"auth_url\":\"https://api.accounts.firefox.com/\",\"oauth_url\":\"https://oauth.accounts.firefox.com/\",\"profile_url\":\"https://profile.accounts.firefox.com/\",\"token_server_endpoint_url\":\"https://token.services.mozilla.com/1.0/sync/1.5\",\"authorization_endpoint\":\"https://accounts.firefox.com/authorization\",\"issuer\":\"https://accounts.firefox.com\",\"jwks_uri\":\"https://oauth.accounts.firefox.com/v1/jwks\",\"token_endpoint\":\"https://oauth.accounts.firefox.com/v1/token\",\"userinfo_endpoint\":\"https://profile.accounts.firefox.com/v1/profile\"},\"login_state\":\"Unknown\",\"oauth_cache\":{\"profile https://identity.mozilla.com/apps/oldsync https://identity.mozilla.com/apps/lockbox\":{\"access_token\":\"42e4bacc8affd23a4ae264fd59ae8ec4a58d5af03b1215daa9cd940f6f80bd9e\",\"keys\":\"{\\\"https://identity.mozilla.com/apps/oldsync\\\":{\\\"kty\\\":\\\"oct\\\",\\\"scope\\\":\\\"https://identity.mozilla.com/apps/oldsync\\\",\\\"k\\\":\\\"VEZDYJ3Jd1Ui0ZVtW8pPHD6LZ48Jd30p-y-PLQQYa0PRcMZtiM6zJO4_I2lxEg__qkxXldPyLiM5PYY9VBD64w\\\",\\\"kid\\\":\\\"1519160140602-WMF1HOhJbtMVueuy3tV4vA\\\"},\\\"https://identity.mozilla.com/apps/lockbox\\\":{\\\"kty\\\":\\\"oct\\\",\\\"scope\\\":\\\"https://identity.mozilla.com/apps/lockbox\\\",\\\"k\\\":\\\"oGGfsZk8xMXtBzGzy2WY3QGPNOTer0VGIC3Uyz9Jy9w\\\",\\\"kid\\\":\\\"1519160141-YqmShzWPQhHp0RNiZs25zg\\\"}}\",\"refresh_token\":\"fd417de6f90683a046070450ead9844a095bee5df934cc0fe3455bd2d41d394a\",\"expires_at\":1531864458,\"scopes\":[\"profile\",\"https://identity.mozilla.com/apps/oldsync\",\"https://identity.mozilla.com/apps/lockbox\"]}}}"

                        self.subject = AccountStore(
                                dispatcher: self.dispatcher,
                                keychainWrapper: self.keychainManager
                        )
                    }

                    xit("pushes a non-nil oauthinfo") {
                        // can't check anything more detailed because we can't construct FxAClient.Profile
                        let oauthInfo = try? self.subject.oauthInfo.toBlocking().first()
                        expect(oauthInfo).notTo(beNil())
                    }
                }

                describe("when the keychain does not have a valid fxa account") {
                    xit("pushes a nil oauthinfo") {
                        let oauthInfo = try? self.subject.oauthInfo.toBlocking().first()
                        expect(oauthInfo).to(beNil())
                    }
                }
            }

            // tricky to test because OAuth is hard to fake out :p
            xdescribe("oauthRedirect") {
                var oauthObserver = self.scheduler.createObserver(OAuthInfo?.self)
                var profileObserver = self.scheduler.createObserver(Profile?.self)

                beforeEach {
                    oauthObserver = self.scheduler.createObserver(OAuthInfo?.self)
                    profileObserver = self.scheduler.createObserver(Profile?.self)

                    self.subject.oauthInfo
                            .bind(to: oauthObserver)
                            .disposed(by: self.disposeBag)

                    self.subject.profile
                            .bind(to: profileObserver)
                            .disposed(by: self.disposeBag)

                    self.dispatcher.fakeRegistration.onNext(AccountAction.oauthRedirect(url: URL(string: "https://lockbox.firefox.com/fxa/ios-redirect.html?code=571e3f5b2d634b844c12e68047be260000927f4babd275638a087b21cc1c40c3&state=wMNWDXCGmjNfru0xfk-iCg&action=signin")!))
                }

                it("saves the accountJSON on successful login") {
                    expect(self.keychainManager.saveArguments[KeychainKey.accountJSON.rawValue]).notTo(beNil())
                }

                it("pushes populated profile and oauthInfo objects to observers") {
                    expect(oauthObserver.events.first!.value.element!).notTo(beNil())
                    expect(profileObserver.events.first!.value.element!).notTo(beNil())
                }
            }

            describe(".clear") {
                beforeEach {
                    self.dispatcher.fakeRegistration.onNext(AccountAction.clear)
                }

                it("clears all available keychain keys") {
                    for key in KeychainKey.allValues {
                        expect(self.keychainManager.removeArguments).to(contain(key.rawValue))
                    }
                }
            }
        }
    }
}

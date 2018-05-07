/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import RxSwift
import RxTest

@testable import Firefox_Lockbox

enum UserInfoStoreSharedExamples: String {
    case SaveScopedKeyToKeychain, SaveProfileInfoToKeychain
}

class UserInfoStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    class FakeKeychainManager: KeychainManager {
        var saveArguments: [KeychainManagerIdentifier: String] = [:]
        var saveSuccess: Bool!
        var retrieveResult: [KeychainManagerIdentifier: String] = [:]

        override func save(_ data: String, identifier: KeychainManagerIdentifier) -> Bool {
            self.saveArguments[identifier] = data
            return saveSuccess
        }

        override func retrieve(_ identifier: KeychainManagerIdentifier) -> String? {
            return retrieveResult[identifier]
        }
    }

    private var dispatcher: FakeDispatcher!
    private var keychainManager: FakeKeychainManager!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: UserInfoStore!

    override func spec() {
        describe("UserInfoStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.keychainManager = FakeKeychainManager()
                self.subject = UserInfoStore(
                        dispatcher: self.dispatcher,
                        keychainManager: self.keychainManager
                )
            }

            describe("scopedKey") {
                var keyObserver = self.scheduler.createObserver(String?.self)
                let key = "fsdlkjsdfljafsdjlkfdsajkldf"

                beforeEach {
                    keyObserver = self.scheduler.createObserver(String?.self)

                    self.subject.scopedKey
                            .bind(to: keyObserver)
                            .disposed(by: self.disposeBag)
                }

                sharedExamples(UserInfoStoreSharedExamples.SaveScopedKeyToKeychain.rawValue) {
                    it("attempts to save the scoped key to the keychain") {
                        expect(self.keychainManager.saveArguments[.scopedKey]).notTo(beNil())
                        expect(self.keychainManager.saveArguments[.scopedKey]).to(equal(key))
                    }
                }

                describe("when the key is saved to the key manager successfully") {
                    beforeEach {
                        self.keychainManager.saveSuccess = true
                        self.dispatcher.fakeRegistration.onNext(UserInfoAction.scopedKey(key: key))
                    }

                    itBehavesLike(UserInfoStoreSharedExamples.SaveScopedKeyToKeychain.rawValue)

                    it("pushes the scopedKey to the observers") {
                        expect(keyObserver.events.last!.value.element!).to(equal(key))
                    }
                }

                describe("when the key is not saved to the key manager successfully") {
                    beforeEach {
                        self.keychainManager.saveSuccess = false
                        self.dispatcher.fakeRegistration.onNext(UserInfoAction.scopedKey(key: key))
                    }

                    itBehavesLike(UserInfoStoreSharedExamples.SaveScopedKeyToKeychain.rawValue)

                    it("does not push the scopedKey to the observers") {
                        expect(keyObserver.events.count).to(be(0))
                    }
                }
            }

            describe("ProfileInfo") {
                var profileInfoObserver = self.scheduler.createObserver(ProfileInfo?.self)
                let profileInfo = ProfileInfo.Builder()
                        .uid("jklfsdlkjdfs")
                        .email("sand@sand.com")
                        .displayName("squasha")
                        .avatar("www.picturesite.com")
                        .build()

                beforeEach {
                    profileInfoObserver = self.scheduler.createObserver(ProfileInfo?.self)

                    self.subject.profileInfo
                            .bind(to: profileInfoObserver)
                            .disposed(by: self.disposeBag)
                }

                sharedExamples(UserInfoStoreSharedExamples.SaveProfileInfoToKeychain.rawValue) {
                    it("attempts to save the uid and email to the keychain") {
                        expect(self.keychainManager.saveArguments[.email]).to(equal(profileInfo.email))
                        expect(self.keychainManager.saveArguments[.uid]).to(equal(profileInfo.uid))
                    }
                }

                describe("when the email & uid are saved successfully to the keychain") {
                    beforeEach {
                        self.keychainManager.saveSuccess = true
                        self.dispatcher.fakeRegistration.onNext(UserInfoAction.profileInfo(info: profileInfo))
                    }

                    itBehavesLike(UserInfoStoreSharedExamples.SaveProfileInfoToKeychain.rawValue)

                    it("pushes the profileInfo to the observer") {
                        expect(profileInfoObserver.events.last!.value.element!).to(equal(profileInfo))
                    }
                }

                describe("when only some of the profileinfo is saved successfully to the keychain") {
                    beforeEach {
                        self.keychainManager.saveSuccess = false
                        self.dispatcher.fakeRegistration.onNext(UserInfoAction.profileInfo(info: profileInfo))
                    }

                    it("pushes nothing to the observer") {
                        expect(profileInfoObserver.events.count).to(be(0))
                    }
                }
            }

            describe("OAuthInfo") {
                var oAuthInfoObserver = self.scheduler.createObserver(OAuthInfo?.self)
                let oauthInfo = OAuthInfo.Builder()
                        .idToken("fdskjldsflkjdfs")
                        .accessToken("mekhjfdsj")
                        .refreshToken("fdssfdjhk")
                        .build()

                beforeEach {
                    oAuthInfoObserver = self.scheduler.createObserver(OAuthInfo?.self)

                    self.subject.oauthInfo
                            .bind(to: oAuthInfoObserver)
                            .disposed(by: self.disposeBag)
                }

                describe("when the tokens are saved successfully to the keychain") {
                    beforeEach {
                        self.keychainManager.saveSuccess = true
                        self.dispatcher.fakeRegistration.onNext(UserInfoAction.oauthInfo(info: oauthInfo))
                    }

                    it("attempts to save the tokens to the keychain") {
                        expect(self.keychainManager.saveArguments[.idToken]).to(equal(oauthInfo.idToken))
                        expect(self.keychainManager.saveArguments[.accessToken]).to(equal(oauthInfo.accessToken))
                        expect(self.keychainManager.saveArguments[.refreshToken]).to(equal(oauthInfo.refreshToken))
                    }

                    it("pushes the oauthInfo to the observer") {
                        expect(oAuthInfoObserver.events.last!.value.element!).to(equal(oauthInfo))
                    }
                }

                describe("when nothing is saved successfully to the keychain") {
                    beforeEach {
                        self.keychainManager.saveSuccess = false
                        self.dispatcher.fakeRegistration.onNext(UserInfoAction.oauthInfo(info: oauthInfo))
                    }

                    it("attempts to save tokens to the keychain") {
                        expect(self.keychainManager.saveArguments[.accessToken]).to(equal(oauthInfo.accessToken))
                    }

                    it("pushes nothing to the observer") {
                        expect(oAuthInfoObserver.events.count).to(equal(0))
                    }
                }
            }

            describe("populating initial values") {
                describe("ProfileInfo") {
                    var profileInfoObserver = self.scheduler.createObserver(ProfileInfo?.self)

                    beforeEach {
                        profileInfoObserver = self.scheduler.createObserver(ProfileInfo?.self)
                    }

                    describe("when both uid and email have previously been saved in the keychain") {
                        let email = "butts@butts.com"
                        let uid = "kjfdslkjsdflkjads"
                        beforeEach {
                            self.keychainManager.retrieveResult[.email] = email
                            self.keychainManager.retrieveResult[.uid] = uid

                            self.subject.profileInfo
                                    .bind(to: profileInfoObserver)
                                    .disposed(by: self.disposeBag)

                            self.dispatcher.fakeRegistration.onNext(UserInfoAction.load)
                        }

                        it("passes the resulting profileinfo object to subscribers") {
                            expect(profileInfoObserver.events.first!.value.element!)
                                    .to(equal(ProfileInfo.Builder().uid(uid).email(email).build()))
                        }
                    }

                    describe("when only uid has been saved in the keychain") {
                        let uid = "kjfdslkjsdflkjads"
                        beforeEach {
                            self.keychainManager.retrieveResult[.uid] = uid

                            self.subject.profileInfo
                                    .bind(to: profileInfoObserver)
                                    .disposed(by: self.disposeBag)

                            self.dispatcher.fakeRegistration.onNext(UserInfoAction.load)
                        }

                        it("passes a nil profileinfo to subscribers") {
                            expect(profileInfoObserver.events.first!.value.element as? ProfileInfo).to(beNil())
                        }
                    }

                    describe("when only email has been saved in the keychain") {
                        let email = "butts@butts.com"
                        beforeEach {
                            self.keychainManager.retrieveResult[.email] = email

                            self.subject.profileInfo
                                    .bind(to: profileInfoObserver)
                                    .disposed(by: self.disposeBag)

                            self.dispatcher.fakeRegistration.onNext(UserInfoAction.load)
                        }

                        it("passes a nil profileinfo to subscribers") {
                            expect(profileInfoObserver.events.first!.value.element as? ProfileInfo).to(beNil())
                        }
                    }

                    describe("when neither have been saved in the keychain") {
                        beforeEach {
                            self.subject.profileInfo
                                    .bind(to: profileInfoObserver)
                                    .disposed(by: self.disposeBag)

                            self.dispatcher.fakeRegistration.onNext(UserInfoAction.load)
                        }

                        it("passes a nil profileinfo to subscribers") {
                            expect(profileInfoObserver.events.first!.value.element as? ProfileInfo).to(beNil())
                        }
                    }
                }

                describe("scopedKey") {
                    var keyObserver = self.scheduler.createObserver(String?.self)
                    let key = "fsdlkjsdfljafsdjlkfdsajkldf"

                    beforeEach {
                        keyObserver = self.scheduler.createObserver(String?.self)
                    }

                    describe("when the scopedKey has previously been saved to the keychain") {
                        beforeEach {
                            self.keychainManager.retrieveResult[.scopedKey] = key

                            self.subject.scopedKey
                                    .bind(to: keyObserver)
                                    .disposed(by: self.disposeBag)

                            self.dispatcher.fakeRegistration.onNext(UserInfoAction.load)
                        }

                        it("stores the key for subsequent observers") {
                            expect(keyObserver.events.first!.value.element!).to(equal(key))
                        }
                    }

                    describe("when the scopedKey has not previously been saved to the keychain") {
                        beforeEach {
                            self.subject.scopedKey
                                    .bind(to: keyObserver)
                                    .disposed(by: self.disposeBag)

                            self.dispatcher.fakeRegistration.onNext(UserInfoAction.load)
                        }

                        it("pushes an nil key to key observers") {
                            expect(keyObserver.events.first!.value.element as? String).to(beNil())
                        }
                    }
                }

                describe("OAuthInfo") {
                    var oAuthInfoObserver = self.scheduler.createObserver(OAuthInfo?.self)

                    beforeEach {
                        oAuthInfoObserver = self.scheduler.createObserver(OAuthInfo?.self)
                    }

                    describe("when all tokens have previously been saved in the keychain") {
                        let accessToken = "meow"
                        let idToken = "kjfdslkjsdflkjads"
                        let refreshToken = "fsdkjlkfsdfddf"

                        beforeEach {
                            self.keychainManager.retrieveResult[.accessToken] = accessToken
                            self.keychainManager.retrieveResult[.idToken] = idToken
                            self.keychainManager.retrieveResult[.refreshToken] = refreshToken

                            self.subject.oauthInfo
                                    .bind(to: oAuthInfoObserver)
                                    .disposed(by: self.disposeBag)

                            self.dispatcher.fakeRegistration.onNext(UserInfoAction.load)
                        }

                        it("passes the resulting oauthInfo object to subscribers") {
                            expect(oAuthInfoObserver.events.first!.value.element!).to(equal(OAuthInfo.Builder()
                                    .idToken(idToken)
                                    .refreshToken(refreshToken)
                                    .accessToken(accessToken)
                                    .build()
                            ))
                        }
                    }

                    describe("when not all tokens have been saved in the keychain") {
                        let accessToken = "meow"
                        let refreshToken = "fsdkjlkfsdfddf"

                        beforeEach {
                            self.keychainManager.retrieveResult[.accessToken] = accessToken
                            self.keychainManager.retrieveResult[.refreshToken] = refreshToken

                            self.subject.oauthInfo
                                    .bind(to: oAuthInfoObserver)
                                    .disposed(by: self.disposeBag)

                            self.dispatcher.fakeRegistration.onNext(UserInfoAction.load)
                        }

                        it("passes a nil OAuthInfo to subscribers") {
                            expect(oAuthInfoObserver.events.first!.value.element as? OAuthInfo).to(beNil())
                        }
                    }

                    describe("when no tokens have been saved in the keychain") {
                        beforeEach {
                            self.subject.oauthInfo
                                    .bind(to: oAuthInfoObserver)
                                    .disposed(by: self.disposeBag)

                            self.dispatcher.fakeRegistration.onNext(UserInfoAction.load)
                        }

                        it("passes an empty OAuthInfo to subscribers") {
                            expect(oAuthInfoObserver.events.first!.value.element as? OAuthInfo).to(beNil())
                        }
                    }
                }
            }
        }
    }
}

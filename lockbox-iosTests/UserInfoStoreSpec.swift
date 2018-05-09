/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox
import SwiftKeychainWrapper

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

    class FakeKeychainManager: KeychainWrapper {
        var saveArguments: [String: String] = [:]
        var saveSuccess: Bool!
        var retrieveResult: [String: String] = [:]

        override func set(_ value: String, forKey key: String, withAccessibility accessibility: SwiftKeychainWrapper.KeychainItemAccessibility? = nil) -> Bool {
            self.saveArguments[key] = value
            return saveSuccess
        }

        override func string(forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> String? {
            return retrieveResult[key]
        }

        init() { super.init(serviceName: "blah") }
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
                        keychainWrapper: self.keychainManager
                )
            }

            describe("ProfileInfo") {
                var profileInfoObserver = self.scheduler.createObserver(ProfileInfo?.self)
                let profileInfo = ProfileInfo.Builder()
                        .email("sand@sand.com")
                        .displayName("squasha")
                        .avatar(URL(string: "www.picturesite.com")!)
                        .build()

                beforeEach {
                    profileInfoObserver = self.scheduler.createObserver(ProfileInfo?.self)

                    self.subject.profileInfo
                            .bind(to: profileInfoObserver)
                            .disposed(by: self.disposeBag)
                }

                sharedExamples(UserInfoStoreSharedExamples.SaveProfileInfoToKeychain.rawValue) {
                    it("attempts to save the email to the keychain") {
                        expect(self.keychainManager.saveArguments[KeychainKey.email.rawValue]).to(equal(profileInfo.email))
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

            describe("populating initial values") {
                describe("ProfileInfo") {
                    var profileInfoObserver = self.scheduler.createObserver(ProfileInfo?.self)

                    beforeEach {
                        profileInfoObserver = self.scheduler.createObserver(ProfileInfo?.self)
                    }

                    describe("when email haa previously been saved in the keychain") {
                        let email = "butts@butts.com"
                        beforeEach {
                            self.keychainManager.retrieveResult[KeychainKey.email.rawValue] = email

                            self.subject.profileInfo
                                    .bind(to: profileInfoObserver)
                                    .disposed(by: self.disposeBag)

                            self.dispatcher.fakeRegistration.onNext(UserInfoAction.load)
                        }

                        it("passes the resulting profileinfo object to subscribers") {
                            expect(profileInfoObserver.events.first!.value.element!)
                                    .to(equal(ProfileInfo.Builder().email(email).build()))
                        }
                    }

                    describe("when no email has been saved in the keychain") {
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
            }
        }
    }
}

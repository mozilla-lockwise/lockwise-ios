/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import AuthenticationServices
import RxSwift
import RxCocoa
import RxBlocking
import Logins

@testable import Lockbox

@available(iOS 12, *)
class CredentialProviderStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let registerStub = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.registerStub.asObservable()
        }
    }

    class FakeDataStore: DataStore {
        let listStub = PublishSubject<[LoginRecord]>()

        override var list: Observable<[LoginRecord]> {
            return self.listStub.asObservable()
        }
    }

    class FakeStoreState: ASCredentialIdentityStoreState {
        var enabledStub: Bool!
        var incrementalUpdateStub: Bool!

        override var isEnabled: Bool {
            return enabledStub
        }

        override var supportsIncrementalUpdates: Bool {
            return incrementalUpdateStub
        }
    }

    class FakeCredentialIdentityStore: CredentialIdentityStoreProtocol {
        var storeState: FakeStoreState!

        var removeCompletion: ((Bool, Error?) -> Void)?

        var credentialIdentities: [ASPasswordCredentialIdentity]?
        var addCompletion: ((Bool, Error?) -> Void)?

        func getState(_ completion: @escaping (ASCredentialIdentityStoreState) -> Void) {
            completion(self.storeState)
        }

        func removeAllCredentialIdentities(_ completion: ((Bool, Error?) -> Void)?) {
            self.removeCompletion = completion
        }

        func saveCredentialIdentities(_ credentialIdentities: [ASPasswordCredentialIdentity], completion: ((Bool, Error?) -> Void)?) {
            self.credentialIdentities = credentialIdentities
            self.addCompletion = completion
        }
    }

    private var dispatcher: FakeDispatcher!
    private var dataStore: FakeDataStore!
    private var credentialIdentityStore: FakeCredentialIdentityStore!

    var subject: CredentialProviderStore!

    override func spec() {
        describe("CredentialProviderStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.dataStore = FakeDataStore()
                self.credentialIdentityStore = FakeCredentialIdentityStore()

                let storeState = FakeStoreState()
                storeState.enabledStub = true
                self.credentialIdentityStore.storeState = storeState

                self.subject = CredentialProviderStore(
                    dispatcher: self.dispatcher,
                    dataStore: self.dataStore,
                    credentialStore: self.credentialIdentityStore)
            }

            describe("init") {
                describe("isEnabled = false") {
                    beforeEach {
                        let storeState = FakeStoreState()
                        storeState.enabledStub = false
                        self.credentialIdentityStore.storeState = storeState

                        self.subject = CredentialProviderStore(
                            dispatcher: self.dispatcher,
                            dataStore: self.dataStore,
                            credentialStore: self.credentialIdentityStore)
                    }

                    it("pushes .NotAllowed") {
                        expect(try! self.subject.state.toBlocking().first()!).to(equal(CredentialProviderStoreState.NotAllowed))
                    }
                }
            }

            describe("clear") {
                beforeEach {
                    self.dispatcher.registerStub.onNext(CredentialProviderAction.clear)
                }

                it("clears the credential store") {
                    expect(self.credentialIdentityStore.removeCompletion).notTo(beNil())
                }
            }

            describe("refresh") {
                describe("when the credential store is not enabled") {
                    beforeEach {
                        let storeState = FakeStoreState()
                        storeState.enabledStub = false
                        self.credentialIdentityStore.storeState = storeState

                        self.subject = CredentialProviderStore(
                            dispatcher: self.dispatcher,
                            dataStore: self.dataStore,
                            credentialStore: self.credentialIdentityStore)
                        self.dispatcher.registerStub.onNext(CredentialProviderAction.refresh)
                    }

                    it("pushes notallowed and does nothing else") {
                        expect(try! self.subject.state.toBlocking().first()!).to(equal(CredentialProviderStoreState.NotAllowed))
                        expect(self.credentialIdentityStore.removeCompletion).to(beNil())
                    }
                }

                describe("when the credential store is enabled and there is a populated logins list") {
                    let guid1 = "fsdsdffds"
                    let hostname1 = "http://www.mozilla.org"
                    let username1 = "dogs@dogs.com"
                    let password1 = "iluvcatz"
                    let guid2 = "lgfdweolkfd"
                    let hostname2 = "http://www.neopets.org"
                    let username2 = "dogs@dogs.com"
                    let password2 = "iwudnvrreusemypw"

                    let logins: [LoginRecord] = [
                        LoginRecord(fromJSONDict: ["id": guid1, "hostname": hostname1, "username": username1, "password": password1]),
                        LoginRecord(fromJSONDict: ["id": guid2, "hostname": hostname2, "username": username2, "password": password2])
                    ]

                    beforeEach {
                        self.dispatcher.registerStub.onNext(CredentialProviderAction.refresh)
                        self.dataStore.listStub.onNext(logins)
                    }

                    it("pushes populating and attempts to clear the credential store") {
                        expect(try! self.subject.state.toBlocking().first()!).to(equal(CredentialProviderStoreState.Populating))
                        expect(self.credentialIdentityStore.removeCompletion).notTo(beNil())
                    }

                    describe("when removing succeeds") {
                        beforeEach {
                            self.credentialIdentityStore.removeCompletion!(true, nil)
                        }

                        it("passes converted ASPasswordCredentialIdentities to the ASCredentialIdentityStore") {
                            let identity1 = self.credentialIdentityStore.credentialIdentities![0]
                            let identity2 = self.credentialIdentityStore.credentialIdentities![1]

                            expect(identity1.user).to(equal(username1))
                            expect(identity1.recordIdentifier).to(equal(guid1))
                            expect(identity1.serviceIdentifier.identifier).to(equal(hostname1))
                            expect(identity2.user).to(equal(username2))
                            expect(identity2.recordIdentifier).to(equal(guid2))
                            expect(identity2.serviceIdentifier.identifier).to(equal(hostname2))

                            expect(self.credentialIdentityStore.addCompletion).notTo(beNil())
                        }

                        describe("when the addition succeeds") {
                            beforeEach {
                                self.credentialIdentityStore.addCompletion!(true, nil)
                            }

                            it("pushes populated") {
                                expect(try! self.subject.state.toBlocking().first()!).to(equal(CredentialProviderStoreState.Populated))
                            }
                        }
                    }
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import AuthenticationServices
import Quick
import Nimble
import Storage

@testable import Lockbox

@available(iOS 12, *)
class CredentialProviderPresenterSpec: QuickSpec {
    class FakeExtensionContext: ASCredentialProviderExtensionContext {
        var extensionConfigurationCompleted = false
        var error: Error?

        var selectedCredential: ASPasswordCredential?
        var completeRequestCompletion: ((Bool) -> Void)?

        override func completeExtensionConfigurationRequest() {
            self.extensionConfigurationCompleted = true
        }

        override func cancelRequest(withError error: Error) {
            self.error = error
        }

        override func completeRequest(withSelectedCredential credential: ASPasswordCredential, completionHandler: ((Bool) -> Void)? = nil) {
            self.selectedCredential = credential
            self.completeRequestCompletion = completionHandler
        }
    }

    class FakeCredentialProviderView: CredentialProviderViewProtocol {
        let fakeExtensionContext = FakeExtensionContext()

        var extensionContext: ASCredentialProviderExtensionContext {
            return self.fakeExtensionContext
        }

        var displayWelcomeCalled = false

        func displayWelcome() {
            self.displayWelcomeCalled = true
        }

        func displayAlertController(buttons: [AlertActionButtonConfiguration], title: String?, message: String?, style: UIAlertController.Style) {
            
        }
    }

    class FakeDispatcher: Dispatcher {
        let registerSubject = PublishSubject<Action>()
        var actionArguments: [Action] = []

        override func dispatch(action: Action) {
            self.actionArguments.append(action)
        }

        override var register: Observable<Action> {
            return self.registerSubject.asObservable()
        }
    }

    class FakeDataStore: DataStore {
        let lockedStub = PublishSubject<Bool>()
        let getStub = PublishSubject<Login?>()

        var getGuid: String?

        override var locked: Observable<Bool> {
            return self.lockedStub.asObservable()
        }

        override func get(_ id: String) -> Observable<Login?> {
            self.getGuid = id
            return self.getStub.asObservable()
        }
    }

    class FakeAccountStore: AccountStore {

    }

    private var view: FakeCredentialProviderView!
    private var dispatcher: FakeDispatcher!
    private var dataStore: FakeDataStore!
    private var accountStore: FakeAccountStore!

    var subject: CredentialProviderPresenter!

    override func spec() {
        fdescribe("CredentialProviderPresenter") {
            beforeEach {
                self.view = FakeCredentialProviderView()
                self.dispatcher = FakeDispatcher()
                self.dataStore = FakeDataStore()
                self.accountStore = FakeAccountStore()

                self.subject = CredentialProviderPresenter(
                    view: self.view,
                    dispatcher: self.dispatcher,
                    accountStore: self.accountStore,
                    dataStore: self.dataStore)
            }

            describe("CredentialStatusAction") {
                beforeEach {
                    self.dispatcher.registerSubject.onNext(CredentialStatusAction.extensionConfigured)
                }

                it("confirms the extension configuration") {
                    expect(self.view.fakeExtensionContext.extensionConfigurationCompleted).to(beTrue())
                }
            }

            describe("extensionConfigurationRequested") {
                beforeEach {
                    self.subject.extensionConfigurationRequested()
                }

                it("foregrounds the datastore and tells the view to display the welcome screen") {
                    expect(self.dispatcher.actionArguments.popLast() as? LifecycleAction).to(equal(LifecycleAction.foreground))
                    expect(self.view.displayWelcomeCalled).to(beTrue())
                }
            }

            describe("credentialProvisionRequested") {
                describe("when the credentialIdentity does not have a record identifier") {
                    let passwordIdentity = ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: "http://www.mozilla.com", type: .URL), user: "dogs@dogs.com", recordIdentifier: nil)
                    beforeEach {
                        self.subject.credentialProvisionRequested(for: passwordIdentity)
                    }

                    describe("locked datastore") {
                        beforeEach {
                            self.dataStore.lockedStub.onNext(true)
                        }

                        it("cancels the request with userInteractionRequired") {
                            expect(self.view.fakeExtensionContext.error).notTo(beNil())
                            expect((self.view.fakeExtensionContext.error! as NSError).code).to(equal(ASExtensionError.userInteractionRequired.rawValue))
                        }
                    }

                    describe("unlocked datastore") {
                        beforeEach {
                            self.dataStore.lockedStub.onNext(false)
                        }

                        it("cancels the request with notFound") {
                            expect(self.view.fakeExtensionContext.error).notTo(beNil())
                            expect((self.view.fakeExtensionContext.error! as NSError).code).to(equal(ASExtensionError.credentialIdentityNotFound.rawValue))
                        }
                    }
                }

                describe("when the credentialIdentity has a record identifier") {
                    let guid = "afsdfdasfdsasf"
                    let passwordIdentity = ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: "http://www.mozilla.com", type: .URL), user: "dogs@dogs.com", recordIdentifier: guid)

                    beforeEach {
                        self.subject.credentialProvisionRequested(for: passwordIdentity)
                    }

                    describe("when the datastore is locked") {
                        beforeEach {
                            self.dataStore.lockedStub.onNext(true)
                        }

                        it("cancels the request with userInteractionRequired") {
                            expect(self.view.fakeExtensionContext.error).notTo(beNil())
                            expect((self.view.fakeExtensionContext.error! as NSError).code).to(equal(ASExtensionError.userInteractionRequired.rawValue))
                        }
                    }

                    describe("when the datastore is unlocked") {
                        beforeEach {
                            self.dataStore.lockedStub.onNext(false)
                        }

                        it("requests the login from the datastore") {
                            expect(self.dataStore.getGuid).to(equal(passwordIdentity.recordIdentifier))
                        }

                        describe("when the login is nil") {
                            beforeEach {
                                self.dataStore.getStub.onNext(nil)
                            }

                            it("cancels the request with notFound") {
                                expect(self.view.fakeExtensionContext.error).notTo(beNil())
                                expect((self.view.fakeExtensionContext.error! as NSError).code).to(equal(ASExtensionError.credentialIdentityNotFound.rawValue))
                            }
                        }

                        describe("when the login is not nil and the password fill completes") {
                            let login = Login(guid: guid, hostname: "http://www.mozilla.com", username: "dogs@dogs.com", password: "meow")

                            beforeEach {
                                self.dataStore.getStub.onNext(login)
                            }

                            it("provides the passwordcredential and touches the password") {
                                expect(self.view.fakeExtensionContext.selectedCredential!.password).to(equal(login.passwordCredential.password))
                                expect(self.view.fakeExtensionContext.selectedCredential!.user).to(equal(login.passwordCredential.user))
                                expect(self.view.fakeExtensionContext.completeRequestCompletion).notTo(beNil())

                                self.view.fakeExtensionContext.completeRequestCompletion!(true)

                                expect(self.dispatcher.actionArguments.popLast()! as? DataStoreAction).to(equal(DataStoreAction.touch(id: guid)))
                            }
                        }
                    }
                }
            }

            describe("credentialProvisionInterface") {
                describe("when the credentialIdentity does not have a record identifier, regardless of locked status") {
                    let passwordIdentity = ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: "http://www.mozilla.com", type: .URL), user: "dogs@dogs.com", recordIdentifier: nil)
                    beforeEach {
                        self.subject.credentialProvisionInterface(for: passwordIdentity)
                    }

                    describe("locked datastore") {
                        beforeEach {
                            self.dataStore.lockedStub.onNext(true)
                        }

                        it("still displays the unlock screen") {
                            expect(self.view.displayWelcomeCalled).to(beTrue())
                        }
                    }

                    describe("unlocked datastore") {
                        beforeEach {
                            self.dataStore.lockedStub.onNext(false)
                        }

                        it("cancels the request with notFound") {
                            expect(self.view.fakeExtensionContext.error).notTo(beNil())
                            expect((self.view.fakeExtensionContext.error! as NSError).code).to(equal(ASExtensionError.credentialIdentityNotFound.rawValue))
                        }
                    }
                }

                describe("when the credentialIdentity has a record identifier") {
                    let guid = "afsdfdasfdsasf"
                    let passwordIdentity = ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: "http://www.mozilla.com", type: .URL), user: "dogs@dogs.com", recordIdentifier: guid)

                    beforeEach {
                        self.subject.credentialProvisionInterface(for: passwordIdentity)
                    }

                    describe("when the datastore is locked") {
                        beforeEach {
                            self.dataStore.lockedStub.onNext(true)
                        }

                        it("displays the welcome screen for unlock") {
                            expect(self.view.displayWelcomeCalled).to(beTrue())
                        }
                    }

                    describe("when the datastore is unlocked") {
                        beforeEach {
                            self.dataStore.lockedStub.onNext(false)
                        }

                        it("requests the login from the datastore") {
                            expect(self.dataStore.getGuid).to(equal(passwordIdentity.recordIdentifier))
                        }

                        describe("when the login is nil") {
                            beforeEach {
                                self.dataStore.getStub.onNext(nil)
                            }

                            it("cancels the request with notFound") {
                                expect(self.view.fakeExtensionContext.error).notTo(beNil())
                                expect((self.view.fakeExtensionContext.error! as NSError).code).to(equal(ASExtensionError.credentialIdentityNotFound.rawValue))
                            }
                        }

                        describe("when the login is not nil and the password fill completes") {
                            let login = Login(guid: guid, hostname: "http://www.mozilla.com", username: "dogs@dogs.com", password: "meow")

                            beforeEach {
                                self.dataStore.getStub.onNext(login)
                            }

                            it("provides the passwordcredential and touches the password") {
                                expect(self.view.fakeExtensionContext.selectedCredential!.password).to(equal(login.passwordCredential.password))
                                expect(self.view.fakeExtensionContext.selectedCredential!.user).to(equal(login.passwordCredential.user))
                                expect(self.view.fakeExtensionContext.completeRequestCompletion).notTo(beNil())

                                self.view.fakeExtensionContext.completeRequestCompletion!(true)

                                expect(self.dispatcher.actionArguments.popLast()! as? DataStoreAction).to(equal(DataStoreAction.touch(id: guid)))
                            }
                        }
                    }
                }
            }
        }
    }
}

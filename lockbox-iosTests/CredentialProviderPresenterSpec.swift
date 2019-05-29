/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import AuthenticationServices
import Quick
import Nimble
import MozillaAppServices

@testable import Lockbox

@available(iOS 12, *)
class CredentialProviderPresenterSpec: QuickSpec {
    class FakeExtensionContext: ASCredentialProviderExtensionContext {
        var extensionConfigurationCompleted = false
        var errorCode: ASExtensionError.Code?

        var selectedCredential: ASPasswordCredential?
        var completeRequestCompletion: ((Bool) -> Void)?

        override func completeExtensionConfigurationRequest() {
            self.extensionConfigurationCompleted = true
        }

        override func cancelRequest(withError error: Error) {
            self.errorCode = ASExtensionError.Code(rawValue: (error as NSError).code)
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
        var displayItemListCalled = false

        func displayWelcome() {
            self.displayWelcomeCalled = true
        }

        func displayItemList() {
            self.displayItemListCalled = true
        }

        func displayAlertController(buttons: [AlertActionButtonConfiguration], title: String?, message: String?, style: UIAlertController.Style, barButtonItem: UIBarButtonItem?) {

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
        let stateStub = ReplaySubject<LoginStoreState>.create(bufferSize: 1)
        let lockedStub = ReplaySubject<Bool>.create(bufferSize: 1)
        let getStub = PublishSubject<LoginRecord?>()

        var getGuid: String?

        override var storageState: Observable<LoginStoreState> {
            return self.stateStub.asObservable()
        }

        override var locked: Observable<Bool> {
            return self.lockedStub.asObservable()
        }

        override func get(_ id: String) -> Observable<LoginRecord?> {
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
        describe("CredentialProviderPresenter") {
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

            describe("passing along sync credentials") {
                describe("nil credentials") {
                    beforeEach {
                        self.accountStore._syncCredentials.onNext(nil)
                    }

                    it("resets the datastore") {
                        let action = self.dispatcher.actionArguments.popLast() as! DataStoreAction
                        expect(action).to(equal(DataStoreAction.reset))
                    }
                }

                describe("populated credentials") {
                    beforeEach {
                        self.accountStore._syncCredentials.onNext(OfflineSyncCredential)
                    }

                    it("passes them along to the datastore") {
                        let action = self.dispatcher.actionArguments.popLast() as! DataStoreAction
                        expect(action).to(equal(DataStoreAction.updateCredentials(syncInfo: OfflineSyncCredential)))
                    }
                }
            }

            describe("CredentialStatusAction") {
                describe("extensionConfigured") {
                    beforeEach {
                        self.dispatcher.registerSubject.onNext(CredentialStatusAction.extensionConfigured)
                    }

                    it("confirms the extension configuration") {
                        expect(self.view.fakeExtensionContext.extensionConfigurationCompleted).to(beTrue())
                    }
                }

                describe("loginSelected") {
                    let guid = "afsdfdasfdsasf"
                    let login = LoginRecord(fromJSONDict: ["id": guid, "hostname": "http://www.mozilla.com", "username": "dogs@dogs.com", "password": "meow"])

                    beforeEach {
                        self.dispatcher.registerSubject.onNext(CredentialStatusAction.loginSelected(login: login))
                        self.dataStore.lockedStub.onNext(false)
                    }

                    it("selects the credential") {
                        expect(self.view.fakeExtensionContext.selectedCredential!.password).to(equal(login.passwordCredential.password))
                        expect(self.view.fakeExtensionContext.selectedCredential!.user).to(equal(login.passwordCredential.user))
                        expect(self.view.fakeExtensionContext.completeRequestCompletion).notTo(beNil())
                    }

                    describe("on completion") {
                        beforeEach {
                            self.view.fakeExtensionContext.completeRequestCompletion!(true)
                        }

                        it("touches the login") {
                            expect(self.dispatcher.actionArguments.popLast()! as? DataStoreAction).to(equal(DataStoreAction.touch(id: guid)))
                        }
                    }
                }

                describe("cancelling") {
                    let code = ASExtensionError.Code.failed

                    beforeEach {
                        self.dispatcher.registerSubject.onNext(CredentialStatusAction.cancelled(error: code))
                    }

                    it("cancels the extension context") {
                        expect(self.view.fakeExtensionContext.errorCode).to(equal(code))
                    }
                }
            }

            describe("extensionConfigurationRequested") {
                beforeEach {
                    self.subject.extensionConfigurationRequested()
                }

                it("tells the view to display the welcome screen") {
                    expect(self.view.displayWelcomeCalled).to(beTrue())
                }

                describe("when the datastore is locked") {
                    beforeEach {
                        self.dataStore.lockedStub.onNext(true)
                    }

                    it("requests authentication") {
                        expect(self.dispatcher.actionArguments.popLast()! as? CredentialProviderAction).to(equal(CredentialProviderAction.authenticationRequested))
                    }
                }

                describe("when the datstore is unlocked") {
                    beforeEach {
                        self.dataStore.lockedStub.onNext(false)
                    }

                    it("refreshes") {
                        expect(self.dispatcher.actionArguments.popLast()! as? CredentialProviderAction).to(equal(CredentialProviderAction.refresh))
                    }
                }
            }

            describe("credentialProvisionRequested") {
                describe("when the datastore is locked") {
                    let passwordIdentity = ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: "http://www.mozilla.com", type: .URL), user: "dogs@dogs.com", recordIdentifier: nil)
                    beforeEach {
                        self.subject.credentialProvisionRequested(for: passwordIdentity)
                        self.dataStore.lockedStub.onNext(true)
                    }

                    it("dispatches the cancellation and requests authentication") {
                        expect(self.dispatcher.actionArguments.popLast()! as? CredentialStatusAction).to(equal(CredentialStatusAction.cancelled(error: .userInteractionRequired)))
                        expect(self.dispatcher.actionArguments.popLast()! as? CredentialProviderAction).to(equal(CredentialProviderAction.authenticationRequested))
                    }
                }

                describe("when the datstore is unlocked") {
                    beforeEach {
                        self.dataStore.lockedStub.onNext(false)
                    }

                    describe("when the credentialIdentity does not have a record identifier") {
                        let passwordIdentity = ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: "http://www.mozilla.com", type: .URL), user: "dogs@dogs.com", recordIdentifier: nil)
                        beforeEach {
                            self.subject.credentialProvisionRequested(for: passwordIdentity)
                        }

                        it("cancels the request with notFound") {
                            expect(self.dispatcher.actionArguments.popLast()! as? CredentialStatusAction).to(equal(CredentialStatusAction.cancelled(error: .credentialIdentityNotFound)))
                        }
                    }

                    describe("when the credentialIdentity has a record identifier") {
                        let guid = "afsdfdasfdsasf"
                        let passwordIdentity = ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: "http://www.mozilla.com", type: .URL), user: "dogs@dogs.com", recordIdentifier: guid)

                        beforeEach {
                            self.subject.credentialProvisionRequested(for: passwordIdentity)
                        }

                        it("requests the login from the datastore") {
                            expect(self.dataStore.getGuid).to(equal(passwordIdentity.recordIdentifier))
                        }

                        describe("when the login is nil") {
                            beforeEach {
                                self.dataStore.getStub.onNext(nil)
                            }

                            it("cancels the request with notFound") {
                                expect(self.dispatcher.actionArguments.popLast()! as? CredentialStatusAction).to(equal(CredentialStatusAction.cancelled(error: .credentialIdentityNotFound)))
                            }
                        }

                        describe("when the login is not nil and the password fill completes") {
                            let login = LoginRecord(fromJSONDict: ["id": guid, "hostname": "http://www.mozilla.com", "username": "dogs@dogs.com", "password": "meow"])

                            beforeEach {
                                self.dataStore.getStub.onNext(login)
                            }

                            it("dispatches the credentialstatusaction") {
                                expect(self.dispatcher.actionArguments.popLast()! as? CredentialStatusAction).to(equal(CredentialStatusAction.loginSelected(login: login)))
                            }
                        }
                    }
                }
            }

            describe("prepareAuthentication") {
                describe("when the datastore is locked") {
                    let passwordIdentity = ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: "http://www.mozilla.com", type: .URL), user: "dogs@dogs.com", recordIdentifier: nil)
                    beforeEach {
                        self.subject.prepareAuthentication(for: passwordIdentity)
                        self.dataStore.lockedStub.onNext(true)
                    }

                    it("displays the welcome view") {
                        expect(self.view.displayWelcomeCalled).to(beTrue())
                    }

                    describe("subsequent pushes when unlocked") {

                        beforeEach {
                            self.dataStore.lockedStub.onNext(false)
                        }

                        describe("when the credentialIdentity does not have a record identifier") {
                            let passwordIdentity = ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: "http://www.mozilla.com", type: .URL), user: "dogs@dogs.com", recordIdentifier: nil)
                            beforeEach {
                                self.subject.prepareAuthentication(for: passwordIdentity)
                            }

                            it("cancels the request with notFound") {
                                expect(self.dispatcher.actionArguments.popLast()! as? CredentialStatusAction).to(equal(CredentialStatusAction.cancelled(error: .credentialIdentityNotFound)))
                            }
                        }

                        describe("when the credentialIdentity has a record identifier") {
                            let guid = "afsdfdasfdsasf"
                            let passwordIdentity = ASPasswordCredentialIdentity(serviceIdentifier: ASCredentialServiceIdentifier(identifier: "http://www.mozilla.com", type: .URL), user: "dogs@dogs.com", recordIdentifier: guid)

                            beforeEach {
                                self.subject.credentialProvisionRequested(for: passwordIdentity)
                            }

                            it("requests the login from the datastore") {
                                expect(self.dataStore.getGuid).to(equal(passwordIdentity.recordIdentifier))
                            }

                            describe("when the login is nil") {
                                beforeEach {
                                    self.dataStore.getStub.onNext(nil)
                                }

                                it("cancels the request with notFound") {
                                    expect(self.dispatcher.actionArguments.popLast()! as? CredentialStatusAction).to(equal(CredentialStatusAction.cancelled(error: .credentialIdentityNotFound)))
                                }
                            }

                            describe("when the login is not nil and the password fill completes") {
                                let login = LoginRecord(fromJSONDict: ["id": guid, "hostname": "http://www.mozilla.com", "username": "dogs@dogs.com", "password": "meow"])

                                beforeEach {
                                    self.dataStore.getStub.onNext(login)
                                }

                                it("dispatches the credentialstatusaction") {
                                    expect(self.dispatcher.actionArguments.popLast()! as? CredentialStatusAction).to(equal(CredentialStatusAction.loginSelected(login: login)))
                                }
                            }
                        }
                    }
                }
            }

            describe("credentialList for identifiers") {
                beforeEach {
                    self.subject.credentialList(for: [] as! [ASCredentialServiceIdentifier])
                }

                describe("when the datastore is unprepared") {
                    beforeEach {
                        self.dataStore.stateStub.onNext(.Unprepared)
                    }

                    it("routes to the welcome view") {
                        expect(self.view.displayWelcomeCalled).to(beTrue())
                    }
                }

                describe("when the datastore is locked") {
                    beforeEach {
                        self.dataStore.lockedStub.onNext(true)
                    }

                    it("displays the welcomeview") {
                        expect(self.view.displayWelcomeCalled).to(beTrue())
                    }

                    describe("subsequent unlocking") {
                        beforeEach {
                            self.dataStore.lockedStub.onNext(false)
                        }

                        it("displays the itemlist") {
                            expect(self.view.displayItemListCalled).to(beTrue())
                        }
                    }
                }

                describe("when the datastore is unlocked") {
                    beforeEach {
                        self.dataStore.lockedStub.onNext(false)
                    }

                    it("displays the itemlist") {
                        expect(self.view.displayItemListCalled).to(beTrue())
                    }
                }
            }

            describe("change display") {
                let traits = UITraitCollection()
                beforeEach {
                    self.subject.changeDisplay(traitCollection: traits)
                }

                it("sends action") {
                    expect(self.dispatcher.actionArguments.popLast()! as? SizeClassAction).to(equal(SizeClassAction.changed(traitCollection: traits)))
                }
            }
        }
    }
}

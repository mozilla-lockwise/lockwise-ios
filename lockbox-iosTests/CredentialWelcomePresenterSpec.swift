/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import AuthenticationServices
import RxSwift
import RxCocoa
import MozillaAppServices

@testable import Lockbox

@available(iOS 12, *)
class CredentialWelcomePresenterSpec: QuickSpec {
    class FakeCredentialProviderView: CredentialWelcomeViewProtocol {
        var spinnerMessage: String?
        var spinnerCompletionMessage: String?

        func displayAlertController(buttons: [AlertActionButtonConfiguration], title: String?, message: String?, style: UIAlertController.Style, barButtonItem: UIBarButtonItem?) {

        }

        func displaySpinner(_ dismiss: Driver<Void>, bag: DisposeBag, message: String, completionMessage: String) {
            self.spinnerMessage = message
            self.spinnerCompletionMessage = completionMessage
        }
    }

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    class FakeCredentialProviderStore: CredentialProviderStore {
        let displayAuthStub = PublishSubject<Bool>()
        let stateStub = PublishSubject<CredentialProviderStoreState>()

        override var displayAuthentication: Observable<Bool> {
            return self.displayAuthStub.asObservable()
        }

        override var state: Observable<CredentialProviderStoreState> {
            return self.stateStub.asObservable()
        }
    }

    class FakeBiometryManager: BiometryManager {
        var authMessage: String?
        var fakeAuthResponse = PublishSubject<Void>()
        var deviceAuthAvailableStub: Bool!

        override func authenticateWithMessage(_ message: String) -> Single<Void> {
            self.authMessage = message
            return fakeAuthResponse.take(1).asSingle()
        }

        override var deviceAuthenticationAvailable: Bool {
            return self.deviceAuthAvailableStub
        }
    }

    class FakeAccountStore: AccountStore {
        let profileStub = PublishSubject<Profile?>()

        override var profile: Observable<Profile?> {
            return self.profileStub.asObservable()
        }
    }

    private var view: FakeCredentialProviderView!
    private var credentialProviderStore: FakeCredentialProviderStore!
    private var accountStore: FakeAccountStore!
    private var dispatcher: FakeDispatcher!
    private var biometryManager: FakeBiometryManager!

    var subject: CredentialWelcomePresenter!

    override func spec() {
        describe("CredentialWelcomePresenter") {
            beforeEach {
                self.view = FakeCredentialProviderView()
                self.credentialProviderStore = FakeCredentialProviderStore()
                self.accountStore = FakeAccountStore()
                self.dispatcher = FakeDispatcher()
                self.biometryManager = FakeBiometryManager()

                self.subject = CredentialWelcomePresenter(
                            view: self.view,
                            dispatcher: self.dispatcher,
                            accountStore: self.accountStore,
                            credentialProviderStore: self.credentialProviderStore,
                            biometryManager: self.biometryManager
                        )
            }

            describe("onViewAppeared") {
                beforeEach {
                    self.subject.onViewAppeared()
                }

                describe("displayAuthentication") {
                    beforeEach {
                        self.credentialProviderStore.displayAuthStub.onNext(true)
                    }

                    // can't construct profile :(
                    xdescribe("when the profile has an email address") {
                        let email = "dogs@dogs.com"

                        beforeEach {
                            //                                self.accountStore.profileStub.onNext(profile)
                        }
                        it("requests authentication") {
                            expect(self.biometryManager.authMessage).to(equal(email))
                        }

                        describe("when device authentication is available") {
                            beforeEach {
                                self.biometryManager.deviceAuthAvailableStub = true
                            }

                            it("dispatches the unlock and authenticated actions when auth succeeds") {
                                self.biometryManager.fakeAuthResponse.onNext(())

                                expect(self.dispatcher.dispatchedActions.popLast()! as? CredentialProviderAction).to(equal(CredentialProviderAction.authenticated))
                                expect(self.dispatcher.dispatchedActions.popLast()! as? DataStoreAction).to(equal(DataStoreAction.unlock))
                            }

                            describe("when device authentication is not available") {
                                beforeEach {
                                    self.biometryManager.deviceAuthAvailableStub = false
                                }

                                it("does not request authentication; just unlocks and dispatches appropriate actions") {
                                    expect(self.biometryManager.authMessage).to(beNil())

                                    expect(self.dispatcher.dispatchedActions.popLast()! as? CredentialProviderAction).to(equal(CredentialProviderAction.authenticated))
                                    expect(self.dispatcher.dispatchedActions.popLast()! as? DataStoreAction).to(equal(DataStoreAction.unlock))
                                }
                            }
                        }
                    }

                    xdescribe("when the profile is nil") {
                        describe("when device authentication is avaialable") {
                            beforeEach {
                                self.biometryManager.deviceAuthAvailableStub = true
                                self.accountStore.profileStub.onNext(nil)
                            }

                            it("requests authentication") {
                                expect(self.biometryManager.authMessage).to(equal(Constant.string.unlockPlaceholder))
                            }

                            it("dispatches the unlock and authenticated actions when auth succeeds") {
                                self.biometryManager.fakeAuthResponse.onNext(())

                                expect(self.dispatcher.dispatchedActions.popLast()! as? CredentialProviderAction).to(equal(CredentialProviderAction.authenticated))
                                expect(self.dispatcher.dispatchedActions.popLast()! as? DataStoreAction).to(equal(DataStoreAction.unlock))
                            }
                        }

                        describe("when device authentication is not available") {
                            beforeEach {
                                self.biometryManager.deviceAuthAvailableStub = false
                                self.accountStore.profileStub.onNext(nil)
                            }

                            it("does not request authentication; just unlocks and dispatches appropriate actions") {
                                expect(self.biometryManager.authMessage).to(beNil())

                                expect(self.dispatcher.dispatchedActions.popLast()! as? CredentialProviderAction).to(equal(CredentialProviderAction.authenticated))
                                expect(self.dispatcher.dispatchedActions.popLast()! as? DataStoreAction).to(equal(DataStoreAction.unlock))
                            }
                        }
                    }
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import AuthenticationServices
import RxSwift
import RxCocoa

@testable import Lockbox

@available(iOS 12, *)
class CredentialWelcomePresenterSpec: QuickSpec {
    class FakeCredentialProviderView: CredentialWelcomeViewProtocol {
        var spinnerMessage: String?
        var spinnerCompletionMessage: String?

        func displayAlertController(buttons: [AlertActionButtonConfiguration], title: String?, message: String?, style: UIAlertController.Style) {

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

    private var view: FakeCredentialProviderView!
    private var credentialProviderStore: FakeCredentialProviderStore!
    private var dispatcher: FakeDispatcher!
    private var biometryManager: FakeBiometryManager!

    var subject: CredentialWelcomePresenter!

    override func spec() {
        fdescribe("CredentialWelcomePresenter") {
            beforeEach {
                self.view = FakeCredentialProviderView()
                self.credentialProviderStore = FakeCredentialProviderStore()
                self.dispatcher = FakeDispatcher()
                self.biometryManager = FakeBiometryManager()

                self.subject = CredentialWelcomePresenter(
                            view: self.view,
                            dispatcher: self.dispatcher,
                            credentialProviderStore: self.credentialProviderStore,
                            biometryManager: self.biometryManager
                        )
            }

            describe("onViewReady") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("displayAuthentication") {
                    describe("when device authentication is available") {
                        beforeEach {
                            self.biometryManager.deviceAuthAvailableStub = true
                            self.credentialProviderStore.displayAuthStub.onNext(true)
                        }

                        it("requests authentication") {
                            expect(self.biometryManager.authMessage).notTo(beNil())
                        }

                        it("dispatches the unlock and authenticated actions when auth succeeds") {
                            self.biometryManager.fakeAuthResponse.onNext(())

                            expect(self.dispatcher.dispatchedActions.popLast()! as? CredentialProviderAction).to(equal(CredentialProviderAction.authenticated))
                            expect(self.dispatcher.dispatchedActions.popLast()! as? DataStoreAction).to(equal(DataStoreAction.unlock))
                        }
                    }

                    describe("when device authentication is available") {
                        beforeEach {
                            self.biometryManager.deviceAuthAvailableStub = false
                            self.credentialProviderStore.displayAuthStub.onNext(true)
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

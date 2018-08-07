/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import Foundation
import RxSwift
import RxCocoa
import RxTest
import UIKit
import CoreGraphics
import LocalAuthentication
import FxAClient

@testable import Lockbox

class WelcomePresenterSpec: QuickSpec {
    class FakeWelcomeView: WelcomeViewProtocol {
        var fakeFxAButtonPress = PublishSubject<Void>()
        var fakeLoginButtonPress = PublishSubject<Void>()
        var fakeUnlockButtonPress = PublishSubject<Void>()
        var firstTimeMessageHiddenStub: TestableObserver<Bool>!
        var firstTimeLearnMoreHiddenStub: TestableObserver<Bool>!
        var firstTimeLearnMoreArrowHiddenStub: TestableObserver<Bool>!
        var loginButtonHiddenStub: TestableObserver<Bool>!
        var unlockButtonHiddenStub: TestableObserver<Bool>!
        var lockImageHiddenStub: TestableObserver<Bool>!
        var alertControllerButtons: [AlertActionButtonConfiguration]?
        var alertControllerTitle: String?
        var alertControllerMessage: String?
        var alertControllerStyle: UIAlertController.Style?

        var loginButtonPressed: ControlEvent<Void> {
            return ControlEvent<Void>(events: fakeLoginButtonPress.asObservable())
        }

        var learnMorePressed: ControlEvent<Void> {
            return ControlEvent<Void>(events: fakeFxAButtonPress.asObservable())
        }

        var unlockButtonPressed: ControlEvent<Void> {
            return ControlEvent<Void>(events: fakeUnlockButtonPress.asObservable())
        }

        var firstTimeLoginMessageHidden: AnyObserver<Bool> {
            return self.firstTimeMessageHiddenStub.asObserver()
        }

        var firstTimeLearnMoreHidden: AnyObserver<Bool> {
            return self.firstTimeLearnMoreHiddenStub.asObserver()
        }

        var firstTimeLearnMoreArrowHidden: AnyObserver<Bool> {
            return self.firstTimeLearnMoreArrowHiddenStub.asObserver()
        }

        var loginButtonHidden: AnyObserver<Bool> {
            return self.loginButtonHiddenStub.asObserver()
        }

        var unlockButtonHidden: AnyObserver<Bool> {
            return self.unlockButtonHiddenStub.asObserver()
        }

        var lockImageHidden: AnyObserver<Bool> {
            return self.lockImageHiddenStub.asObserver()
        }

        func displayAlertController(buttons: [AlertActionButtonConfiguration],
                                    title: String?,
                                    message: String?,
                                    style: UIAlertController.Style) {
            self.alertControllerButtons = buttons
            self.alertControllerTitle = title
            self.alertControllerMessage = message
            self.alertControllerStyle = style
        }
    }

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    class FakeAccountStore: AccountStore {
        var fakeProfile = PublishSubject<Profile?>()
        var fakeOldAccountInformation = PublishSubject<Bool>()

        override var profile: Observable<Profile?> {
            return self.fakeProfile.asObservable()
        }

        override var hasOldAccountInformation: Observable<Bool> {
            return self.fakeOldAccountInformation.asObservable()
        }
    }

    class FakeDataStore: DataStore {
        let fakeLocked: ReplaySubject<Bool>

        init() {
            self.fakeLocked = ReplaySubject<Bool>.create(bufferSize: 1)
            super.init()

            self.disposeBag = DisposeBag()
        }

        override var locked: Observable<Bool> {
            return self.fakeLocked.asObservable()
        }
    }

    class FakeLifecycleStore: LifecycleStore {
        var fakeCycle = PublishSubject<LifecycleAction>()

        override var lifecycleFilter: Observable<LifecycleAction> {
            return self.fakeCycle.asObservable()
        }
    }

    class FakeBiometryManager: BiometryManager {
        var authMessage: String?
        var fakeAuthResponse = PublishSubject<Void>()
        var deviceAuthAvailableStub: Bool!
        var touchIDStub: Bool = false
        var faceIDStub: Bool = false

        override func authenticateWithMessage(_ message: String) -> Single<Void> {
            self.authMessage = message
            return fakeAuthResponse.take(1).asSingle()
        }

        override var deviceAuthenticationAvailable: Bool {
            return self.deviceAuthAvailableStub
        }

        override var usesTouchID: Bool {
            return self.touchIDStub
        }

        override var usesFaceID: Bool {
            return self.faceIDStub
        }
    }

    private var view: FakeWelcomeView!
    private var dispatcher: FakeDispatcher!
    private var accountStore: FakeAccountStore!
    private var dataStore: FakeDataStore!
    private var lifecycleStore: FakeLifecycleStore!
    private var biometryManager: FakeBiometryManager!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: WelcomePresenter!

    override func spec() {
        describe("WelcomePresenter") {
            beforeEach {
                self.view = FakeWelcomeView()
                self.view.firstTimeMessageHiddenStub = self.scheduler.createObserver(Bool.self)
                self.view.firstTimeLearnMoreHiddenStub = self.scheduler.createObserver(Bool.self)
                self.view.firstTimeLearnMoreArrowHiddenStub = self.scheduler.createObserver(Bool.self)
                self.view.loginButtonHiddenStub = self.scheduler.createObserver(Bool.self)
                self.view.unlockButtonHiddenStub = self.scheduler.createObserver(Bool.self)
                self.view.lockImageHiddenStub = self.scheduler.createObserver(Bool.self)

                self.dispatcher = FakeDispatcher()
                self.accountStore = FakeAccountStore()
                self.dataStore = FakeDataStore()
                self.lifecycleStore = FakeLifecycleStore()
                self.biometryManager = FakeBiometryManager()
                self.subject = WelcomePresenter(
                        view: self.view,
                        dispatcher: self.dispatcher,
                        accountStore: self.accountStore,
                        dataStore: self.dataStore,
                        lifecycleStore: self.lifecycleStore,
                        biometryManager: self.biometryManager
                )
            }

            describe("onViewReady") {
                describe("when the device is unlocked (first time login)") {
                    beforeEach {
                        self.biometryManager.deviceAuthAvailableStub = true
                        self.dataStore.fakeLocked.onNext(false)
                        self.subject.onViewReady()
                    }

                    it("shows the first time login message and the fxa login button") {
                        expect(self.view.firstTimeMessageHiddenStub.events.last!.value.element).to(beFalse())
                        expect(self.view.loginButtonHiddenStub.events.last!.value.element).to(beFalse())
                        expect(self.view.firstTimeLearnMoreHiddenStub.events.last!.value.element).to(beFalse())
                        expect(self.view.firstTimeLearnMoreArrowHiddenStub.events.last!.value.element).to(beFalse())
                    }

                    it("hides the biometrics login button and label") {
                        expect(self.view.unlockButtonHiddenStub.events.last!.value.element).to(beTrue())
                        expect(self.view.lockImageHiddenStub.events.last!.value.element).to(beTrue())
                    }
                }

                describe("when the user has old account information") {
                    beforeEach {
                        self.subject.onViewReady()
                        self.accountStore.fakeOldAccountInformation.onNext(true)
                    }

                    it("launches an alert") {
                        expect(self.view.alertControllerTitle).to(equal(Constant.string.reauthenticationRequired))
                        expect(self.view.alertControllerMessage).to(equal(Constant.string.appUpdateDisclaimer))
                        expect(self.view.alertControllerStyle).to(equal(UIAlertControllerStyle.alert))
                    }

                    describe("tapping Continue") {
                        beforeEach {
                            self.view.alertControllerButtons![0].tapObserver!.onNext(())
                        }

                        it("routes to FxA, and sends the appropriate account action") {
                            let accountArg = self.dispatcher.dispatchedActions.popLast() as! AccountAction
                            expect(accountArg).to(equal(AccountAction.oauthSignInMessageRead))
                            let argument = self.dispatcher.dispatchedActions.popLast() as! LoginRouteAction
                            expect(argument).to(equal(LoginRouteAction.fxa))
                        }
                    }
                }

                describe("receiving a login button press") {
                    describe("when the user has device authentication available") {
                        beforeEach {
                            self.biometryManager.deviceAuthAvailableStub = true
                            self.subject.onViewReady()
                            self.view.fakeLoginButtonPress.onNext(())
                        }

                        it("dispatches the fxa login route action") {
                            let argument = self.dispatcher.dispatchedActions.popLast() as! LoginRouteAction
                            expect(argument).to(equal(.fxa))
                        }
                    }

                    describe("when the user does not have device authentication available") {
                        beforeEach {
                            self.biometryManager.deviceAuthAvailableStub = false
                            self.subject.onViewReady()
                            self.view.fakeLoginButtonPress.onNext(())
                        }

                        it("displays a directional / informative alert") {
                            expect(self.view.alertControllerTitle).to(equal(Constant.string.notUsingPasscode))
                            expect(self.view.alertControllerMessage).to(equal(Constant.string.passcodeInformation))
                            expect(self.view.alertControllerStyle).to(equal(UIAlertController.Style.alert))
                        }

                        describe("tapping the Skip button") {
                            beforeEach {
                                self.view.alertControllerButtons![0].tapObserver!.onNext(())
                            }

                            it("dispatches the fxa login route action") {
                                let argument = self.dispatcher.dispatchedActions.popLast() as! LoginRouteAction
                                expect(argument).to(equal(.fxa))
                            }
                        }

                        describe("tapping the set passcode button") {
                            beforeEach {
                                self.view.alertControllerButtons![1].tapObserver!.onNext(())
                            }

                            it("routes to the touchid / passcode settings page") {
                                let action = self.dispatcher.dispatchedActions.popLast() as! SettingLinkAction
                                expect(action).to(equal(.touchIDPasscode))
                            }
                        }
                    }
                }

                describe("receiving a learn more button press") {
                    beforeEach {
                        self.biometryManager.deviceAuthAvailableStub = true
                        self.subject.onViewReady()
                        self.view.fakeFxAButtonPress.onNext(())
                    }

                    it("dispatches the learn more route action") {
                        let argument = self.dispatcher.dispatchedActions.popLast() as! ExternalWebsiteRouteAction
                        expect(argument).to(equal(ExternalWebsiteRouteAction(
                                urlString: Constant.app.useLockboxFAQ,
                                title: Constant.string.learnMore,
                                returnRoute: LoginRouteAction.welcome)))
                    }
                }

                describe("when the device is locked") {
                    let email = "example@example.com"

                    // TODO: remove pended spec when mozilla/application-services#133 is resolved
                    xdescribe("when the profileinfo has an email address") {
                        beforeEach {
                            self.biometryManager.deviceAuthAvailableStub = true
                            self.subject.onViewReady()
                            self.dataStore.fakeLocked.onNext(true)
                            // tricky to test because we cannot construct a Profile with the email
                            self.accountStore.fakeProfile.onNext(nil)
                        }

                        it("hides the first time login message and the fxa login button") {
                            expect(self.view.firstTimeMessageHiddenStub.events.last!.value.element).to(beTrue())
                            expect(self.view.loginButtonHiddenStub.events.last!.value.element).to(beTrue())
                            expect(self.view.firstTimeLearnMoreHiddenStub.events.last!.value.element).to(beTrue())
                            expect(self.view.firstTimeLearnMoreArrowHiddenStub.events.last!.value.element).to(beTrue())
                        }

                        it("shows the biometrics login button and label") {
                            expect(self.view.unlockButtonHiddenStub.events.last!.value.element).to(beFalse())
                            expect(self.view.lockImageHiddenStub.events.last!.value.element).to(beFalse())
                        }

                        describe("when device authentication is available") {
                            describe("foregrounding actions") {
                                beforeEach {
                                    self.lifecycleStore.fakeCycle.onNext(LifecycleAction.foreground)
                                }

                                it("starts authentication") {
                                    expect(self.biometryManager.authMessage).to(equal(email))
                                }

                                describe("successful authentication") {
                                    beforeEach {
                                        self.biometryManager.fakeAuthResponse.onNext(())
                                    }

                                    it("unlocks the application") {
                                        let action = self.dispatcher.dispatchedActions.popLast() as! DataStoreAction
                                        expect(action).to(equal(.unlock))
                                    }
                                }

                                describe("unsuccessful authentication") {
                                    beforeEach {
                                        self.biometryManager.fakeAuthResponse.onError(NSError(domain: "localauthentication", code: -1))
                                    }

                                    it("does nothing") {
                                        expect(self.dispatcher.dispatchedActions).to(beEmpty())
                                    }
                                }
                            }

                            describe("pressing the biometrics button") {
                                beforeEach {
                                    self.view.fakeUnlockButtonPress.onNext(())
                                }

                                it("starts authentication") {
                                    expect(self.biometryManager.authMessage).to(equal(email))
                                }

                                describe("successful authentication") {
                                    beforeEach {
                                        self.biometryManager.fakeAuthResponse.onNext(())
                                    }

                                    it("unlocks the application") {
                                        let action = self.dispatcher.dispatchedActions.popLast() as! DataStoreAction
                                        expect(action).to(equal(.unlock))
                                    }
                                }

                                describe("unsuccessful authentication") {
                                    beforeEach {
                                        self.biometryManager.fakeAuthResponse.onError(NSError(domain: "localauthentication", code: -1))
                                    }

                                    it("does nothing") {
                                        expect(self.dispatcher.dispatchedActions).to(beEmpty())
                                    }
                                }
                            }
                        }

                        describe("when device authentication is not available") {
                            beforeEach {
                                self.biometryManager.deviceAuthAvailableStub = false
                                self.lifecycleStore.fakeCycle.onNext(LifecycleAction.foreground)
                            }

                            it("unlocks the device blindly") {
                                let action = self.dispatcher.dispatchedActions.popLast() as! DataStoreAction
                                expect(action).to(equal(.unlock))
                            }
                        }
                    }

                    describe("when the profileinfo does not exist") {
                        beforeEach {
                            self.biometryManager.deviceAuthAvailableStub = true
                            self.subject.onViewReady()
                            self.dataStore.fakeLocked.onNext(true)
                            self.accountStore.fakeProfile.onNext(nil)
                        }

                        it("hides the first time login message and the fxa login button") {
                            expect(self.view.firstTimeMessageHiddenStub.events.last!.value.element).to(beTrue())
                            expect(self.view.loginButtonHiddenStub.events.last!.value.element).to(beTrue())
                            expect(self.view.firstTimeLearnMoreHiddenStub.events.last!.value.element).to(beTrue())
                            expect(self.view.firstTimeLearnMoreArrowHiddenStub.events.last!.value.element).to(beTrue())
                        }

                        it("shows the biometrics login button and label") {
                            expect(self.view.unlockButtonHiddenStub.events.last!.value.element).to(beFalse())
                            expect(self.view.lockImageHiddenStub.events.last!.value.element).to(beFalse())
                        }

                        describe("when device authentication is available") {
                            describe("foregrounding actions") {
                                beforeEach {
                                    self.lifecycleStore.fakeCycle.onNext(LifecycleAction.foreground)
                                }

                                it("starts authentication") {
                                    expect(self.biometryManager.authMessage).to(equal(Constant.string.unlockPlaceholder))
                                }

                                describe("successful authentication") {
                                    beforeEach {
                                        self.biometryManager.fakeAuthResponse.onNext(())
                                    }

                                    it("unlocks the application") {
                                        let action = self.dispatcher.dispatchedActions.popLast() as! DataStoreAction
                                        expect(action).to(equal(.unlock))
                                    }
                                }

                                describe("unsuccessful authentication") {
                                    beforeEach {
                                        self.biometryManager.fakeAuthResponse.onError(NSError(domain: "localauthentication", code: -1))
                                    }

                                    it("does nothing") {
                                        expect(self.dispatcher.dispatchedActions).to(beEmpty())
                                    }
                                }
                            }

                            describe("pressing the unlock button") {
                                beforeEach {
                                    self.view.fakeUnlockButtonPress.onNext(())
                                }

                                it("starts authentication") {
                                    expect(self.biometryManager.authMessage).to(equal(Constant.string.unlockPlaceholder))
                                }

                                describe("successful authentication") {
                                    beforeEach {
                                        self.biometryManager.fakeAuthResponse.onNext(())
                                    }

                                    it("unlocks the application") {
                                        let action = self.dispatcher.dispatchedActions.popLast() as! DataStoreAction
                                        expect(action).to(equal(.unlock))
                                    }
                                }

                                describe("unsuccessful authentication") {
                                    beforeEach {
                                        self.biometryManager.fakeAuthResponse.onError(NSError(domain: "localauthentication", code: -1))
                                    }

                                    it("does nothing") {
                                        expect(self.dispatcher.dispatchedActions).to(beEmpty())
                                    }
                                }
                            }
                        }

                        describe("when device authentication is not available") {
                            beforeEach {
                                self.biometryManager.deviceAuthAvailableStub = false
                                self.lifecycleStore.fakeCycle.onNext(LifecycleAction.foreground)
                            }

                            it("unlocks the device blindly") {
                                let action = self.dispatcher.dispatchedActions.popLast() as! DataStoreAction
                                expect(action).to(equal(.unlock))
                            }
                        }
                    }
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import Foundation
import RxSwift
import RxCocoa
import RxTest
import CoreGraphics
import LocalAuthentication

@testable import Lockbox

class WelcomePresenterSpec: QuickSpec {
    class FakeWelcomeView: WelcomeViewProtocol {
        var fakeButtonPress = PublishSubject<Void>()
        var firstTimeMessageHiddenStub: TestableObserver<Bool>!
        var biometricAuthMessageHiddenStub: TestableObserver<Bool>!
        var biometricSignInTextStub: TestableObserver<String?>!
        var biometricImageNameStub: TestableObserver<String>!
        var fxaButtonTopSpaceStub: TestableObserver<CGFloat>!

        var loginButtonPressed: ControlEvent<Void> {
            return ControlEvent<Void>(events: fakeButtonPress.asObservable())
        }

        var biometricSignInButtonPressed: ControlEvent<Void> {
            return ControlEvent<Void>(events: fakeButtonPress.asObservable())
        }

        var firstTimeLoginMessageHidden: AnyObserver<Bool> {
            return self.firstTimeMessageHiddenStub.asObserver()
        }
        var biometricAuthenticationPromptHidden: AnyObserver<Bool> {
            return self.biometricAuthMessageHiddenStub.asObserver()
        }

        var biometricSignInText: AnyObserver<String?> {
            return self.biometricSignInTextStub.asObserver()
        }

        var biometricImageName: AnyObserver<String> {
            return self.biometricImageNameStub.asObserver()
        }

        var fxAButtonTopSpace: AnyObserver<CGFloat> {
            return self.fxaButtonTopSpaceStub.asObserver()
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeArgument = action
        }
    }

    class FakeSettingActionHandler: SettingActionHandler {
        var invokeArgument: SettingAction?

        override func invoke(_ action: SettingAction) {
            self.invokeArgument = action
        }
    }

    class FakeBiometryManager: BiometryManager {
        var faceIdStub: Bool!
        var touchIdStub: Bool!
        var authMessage: String?
        var fakeAuthResponse = PublishSubject<Void>()

        override var usesTouchID: Bool {
            return self.touchIdStub
        }

        override var usesFaceID: Bool {
            return self.faceIdStub
        }

        override func authenticateWithMessage(_ message: String) -> Single<Void> {
            self.authMessage = message
            return fakeAuthResponse.take(1).asSingle()
        }
    }

    private var view: FakeWelcomeView!
    private var routeActionHandler: FakeRouteActionHandler!
    private var scheduler = TestScheduler(initialClock: 0)
    var subject: WelcomePresenter!

    override func spec() {

        describe("LoginPresenter") {
            beforeEach {
                self.view = FakeWelcomeView()
                self.view.firstTimeMessageHiddenStub = self.scheduler.createObserver(Bool.self)
                self.view.biometricAuthMessageHiddenStub = self.scheduler.createObserver(Bool.self)
                self.view.biometricSignInTextStub = self.scheduler.createObserver(String?.self)
                self.view.biometricImageNameStub = self.scheduler.createObserver(String.self)
                self.view.fxaButtonTopSpaceStub = self.scheduler.createObserver(CGFloat.self)

                self.routeActionHandler = FakeRouteActionHandler()
                self.subject = WelcomePresenter(view: self.view, routeActionHandler: self.routeActionHandler)
            }

            describe("onViewReady") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("when the device is locked") {
                    beforeEach {
                        UserDefaults.standard.set(true, forKey: SettingKey.locked.rawValue)
                    }

                    describe("when touchID is available") {

                    }

                    describe("when biometrics are enabled") {
                        beforeEach {
                            UserDefaults.standard.set(true, forKey: SettingKey.biometricLogin.rawValue)
                        }

                        it("hides the first time login message") {
                            expect(self.view.firstTimeMessageHiddenStub.events.last!.value.element).to(beTrue())
                        }

                        it("moves the FxA button up") {
                            expect(self.view.fxaButtonTopSpaceStub.events.last!.value.element).to(equal(Constant.number.fxaButtonTopSpaceUnlock))
                        }

                        it("shows the biometric auth prompt button") {
                            expect(self.view.biometricAuthMessageHiddenStub.events.last!.value.element).to(beFalse())
                        }
                    }

                    describe("when biometrics are not enabled") {
                        beforeEach {
                            UserDefaults.standard.set(false, forKey: SettingKey.biometricLogin.rawValue)
                        }

                        it("hides the first time login message") {
                            expect(self.view.firstTimeMessageHiddenStub.events.last!.value.element).to(beTrue())
                        }

                        it("moves the FxA button up") {
                            expect(self.view.fxaButtonTopSpaceStub.events.last!.value.element).to(equal(Constant.number.fxaButtonTopSpaceUnlock))
                        }

                        it("hides the biometric auth prompt button") {
                            expect(self.view.biometricAuthMessageHiddenStub.events.last!.value.element).to(beTrue())
                        }
                    }
                }

                describe("when the device is unlocked (first time login)") {
                    beforeEach {
                        UserDefaults.standard.set(false, forKey: SettingKey.locked.rawValue)
                    }

                    it("hides the first time login message") {
                        expect(self.view.firstTimeMessageHiddenStub.events.last!.value.element).to(beFalse())
                    }

                    it("moves the FxA button up") {
                        expect(self.view.fxaButtonTopSpaceStub.events.last!.value.element).to(equal(Constant.number.fxaButtonTopSpaceFirstLogin))
                    }

                    it("hides the biometric auth prompt button") {
                        expect(self.view.biometricAuthMessageHiddenStub.events.last!.value.element).to(beTrue())
                    }
                }

                describe("receiving a login button press") {
                    beforeEach {
                        self.view.fakeButtonPress.onNext(())
                    }

                    it("dispatches the fxa login route action") {
                        expect(self.routeActionHandler.invokeArgument).notTo(beNil())
                        let argument = self.routeActionHandler.invokeArgument as! LoginRouteAction
                        expect(argument).to(equal(LoginRouteAction.fxa))
                    }
                }
            }
        }
    }
}

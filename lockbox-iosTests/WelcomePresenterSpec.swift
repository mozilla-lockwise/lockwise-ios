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

@testable import Firefox_Lockbox

class WelcomePresenterSpec: QuickSpec {
    class FakeWelcomeView: WelcomeViewProtocol {
        var fakeFxAButtonPress = PublishSubject<Void>()
        var fakeBiometricButtonPress = PublishSubject<Void>()
        var firstTimeMessageHiddenStub: TestableObserver<Bool>!
        var biometricAuthMessageHiddenStub: TestableObserver<Bool>!
        var biometricSignInTextStub: TestableObserver<String?>!
        var biometricImageNameStub: TestableObserver<String>!
        var fxaButtonTopSpaceStub: TestableObserver<CGFloat>!

        var loginButtonPressed: ControlEvent<Void> {
            return ControlEvent<Void>(events: fakeFxAButtonPress.asObservable())
        }

        var biometricSignInButtonPressed: ControlEvent<Void> {
            return ControlEvent<Void>(events: fakeBiometricButtonPress.asObservable())
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

    class FakeUserInfoStore: UserInfoStore {
        var fakeProfileInfo = PublishSubject<ProfileInfo?>()

        override var profileInfo: Observable<ProfileInfo?> {
            return self.fakeProfileInfo.asObservable()
        }
    }

    class FakeBiometryManager: BiometryManager {
        var faceIdStub = false
        var touchIdStub = false
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
    private var settingActionHandler: FakeSettingActionHandler!
    private var userInfoStore: FakeUserInfoStore!
    private var biometryManager: FakeBiometryManager!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
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
                self.settingActionHandler = FakeSettingActionHandler()
                self.userInfoStore = FakeUserInfoStore()
                self.biometryManager = FakeBiometryManager()
                self.subject = WelcomePresenter(
                        view: self.view,
                        routeActionHandler: self.routeActionHandler,
                        settingActionHandler: self.settingActionHandler,
                        userInfoStore: self.userInfoStore,
                        biometryManager: self.biometryManager
                )
            }

            describe("onViewReady") {
                describe("when the device is locked") {
                    beforeEach {
                        UserDefaults.standard.set(true, forKey: SettingKey.locked.rawValue)
                    }

                    describe("when touchID is available") {
                        beforeEach {
                            self.biometryManager.touchIdStub = true
                            self.biometryManager.faceIdStub = false
                            self.subject.onViewReady()
                        }

                        it("passes the touchID string and image name") {
                            expect(self.view.biometricSignInTextStub.events.first!.value.element).to(equal(Constant.string.signInTouchID))
                            expect(self.view.biometricImageNameStub.events.first!.value.element).to(equal("fingerprint"))
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

                    describe("when faceID is available") {
                        beforeEach {
                            self.biometryManager.touchIdStub = false
                            self.biometryManager.faceIdStub = true
                            self.subject.onViewReady()
                        }

                        it("passes the touchID string and image name") {
                            expect(self.view.biometricSignInTextStub.events.first!.value.element).to(equal(Constant.string.signInFaceID))
                            expect(self.view.biometricImageNameStub.events.first!.value.element).to(equal("face"))
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

                    describe("when neither face nor touchID are enabled") {
                        beforeEach {
                            self.biometryManager.touchIdStub = false
                            self.biometryManager.faceIdStub = false
                            self.subject.onViewReady()
                        }

                        it("doesn't set the biometric button text or image") {
                            expect(self.view.biometricSignInTextStub.events.count).to(equal(0))
                            expect(self.view.biometricImageNameStub.events.count).to(equal(0))
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

                            it("still hides the biometric auth prompt button") {
                                expect(self.view.biometricAuthMessageHiddenStub.events.last!.value.element).to(beTrue())
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
                }

                describe("when the device is unlocked (first time login)") {
                    beforeEach {
                        UserDefaults.standard.set(false, forKey: SettingKey.locked.rawValue)
                        self.subject.onViewReady()
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
                        self.subject.onViewReady()
                        self.view.fakeFxAButtonPress.onNext(())
                    }

                    it("dispatches the fxa login route action") {
                        expect(self.routeActionHandler.invokeArgument).notTo(beNil())
                        let argument = self.routeActionHandler.invokeArgument as! LoginRouteAction
                        expect(argument).to(equal(LoginRouteAction.fxa))
                    }
                }

                describe("receiving a biometricsignin button tap") {
                    let email = "butts@butts.com"

                    beforeEach {
                        self.subject.onViewReady()
                        self.userInfoStore.fakeProfileInfo.onNext(ProfileInfo.Builder().email(email).build())
                        self.view.fakeBiometricButtonPress.onNext(())
                    }

                    it("begins authentication with the profileInfo email") {
                        expect(self.biometryManager.authMessage).to(equal(email))
                    }

                    describe("successful authentication") {
                        beforeEach {
                            self.biometryManager.fakeAuthResponse.onNext(())
                        }

                        it("unlocks the application & routes to the list") {
                            expect(self.settingActionHandler.invokeArgument).to(equal(SettingAction.visualLock(locked: false)))
                            let argument = self.routeActionHandler.invokeArgument as! MainRouteAction
                            expect(argument).to(equal(MainRouteAction.list))
                        }
                    }

                    describe("unsuccessful authentication") {
                        beforeEach {
                            self.biometryManager.fakeAuthResponse.onError(NSError(domain: "localauthentication", code: -1))
                        }

                        it("does nothing") {
                            expect(self.settingActionHandler.invokeArgument).to(beNil())
                            expect(self.routeActionHandler.invokeArgument).to(beNil())
                        }

                        describe("subsequent attempts with successful authentication") {
                            beforeEach {
                                self.biometryManager.authMessage = nil
                                self.biometryManager.fakeAuthResponse = PublishSubject<Void>()
                                self.view.fakeBiometricButtonPress.onNext(())
                            }

                            it("begins authentication with the profileInfo email") {
                                expect(self.biometryManager.authMessage).to(equal(email))
                            }

                            it("unlocks the application & routes to the list") {
                                self.biometryManager.fakeAuthResponse.onNext(())

                                expect(self.settingActionHandler.invokeArgument).to(equal(SettingAction.visualLock(locked: false)))
                                let argument = self.routeActionHandler.invokeArgument as! MainRouteAction
                                expect(argument).to(equal(MainRouteAction.list))
                            }
                        }
                    }
                }
            }
        }
    }
}

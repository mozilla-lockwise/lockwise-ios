/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift

@testable import Lockbox

class BiometryOnboardingPresenterSpec: QuickSpec {
    class FakeBiometryOnboardingView: BiometryOnboardingViewProtocol {
        let enableStub = PublishSubject<Void>()
        let notNowStub = PublishSubject<Void>()
        var iPhoneXStub: Bool!
        var biometricImageName: String?
        var biometricTitle: String?
        var biometricSubTitle: String?

        var enableTapped: Observable<Void> {
            return self.enableStub.asObservable()
        }

        var notNowTapped: Observable<Void> {
            return self.notNowStub.asObservable()
        }

        var hasFaceID: Bool {
            return self.iPhoneXStub
        }

        func setBiometricsImageName(_ name: String) {
            self.biometricImageName = name
        }

        func setBiometricsTitle(_ title: String) {
            self.biometricTitle = title
        }

        func setBiometricsSubTitle(_ subTitle: String) {
            self.biometricSubTitle = subTitle
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeArgument = action
        }
    }

    class FakeSettingActionHandler: SettingActionHandler {
        var actionArgument: SettingAction?

        override func invoke(_ action: SettingAction) {
            actionArgument = action
        }
    }

    class FakeBiometryManager: BiometryManager {
        var auth = PublishSubject<Void>()
        var message: String?

        override func authenticateWithBiometrics(message: String) -> Single<Void> {
            self.message = message
            return auth.take(1).asSingle()
        }
    }

    private var view: FakeBiometryOnboardingView!
    private var routeActionHandler: FakeRouteActionHandler!
    private var settingActionHandler: FakeSettingActionHandler!
    private var biometryManager: FakeBiometryManager!
    var subject: BiometryOnboardingPresenter!

    override func spec() {
        describe("BiometryOnboardingPresenter") {
            beforeEach {
                self.view = FakeBiometryOnboardingView()
                self.routeActionHandler = FakeRouteActionHandler()
                self.settingActionHandler = FakeSettingActionHandler()
                self.biometryManager = FakeBiometryManager()
                self.subject = BiometryOnboardingPresenter(
                        view: self.view,
                        routeActionHandler: self.routeActionHandler,
                        settingActionHandler: self.settingActionHandler,
                        biometryManager: self.biometryManager
                )
            }

            describe("onViewReady") {
                describe("when on the iPhone X") {
                    beforeEach {
                        self.view.iPhoneXStub = true
                        self.subject.onViewReady()
                    }

                    it("sets the appropriate content") {
                        expect(self.view.biometricImageName).to(equal("face-large"))
                        expect(self.view.biometricTitle).to(equal(Constant.string.onboardingFaceIDHeader))
                        expect(self.view.biometricSubTitle).to(equal(Constant.string.onboardingFaceIDSubtitle))
                    }

                    describe("enableTapped") {
                        beforeEach {
                            self.view.enableStub.onNext(())
                        }

                        it("sets the biometric login enabled & routes to the list") {
                            expect(self.settingActionHandler.actionArgument).to(equal(SettingAction.biometricLogin(enabled: true)))
                            let route = self.routeActionHandler.invokeArgument as! MainRouteAction
                            expect(route).to(equal(MainRouteAction.list))
                        }

                        it("authenticates with faceID") {
                            expect(self.biometryManager.message).to(equal(""))
                        }
                    }

                    describe("notNowTapped") {
                        beforeEach {
                            self.view.notNowStub.onNext(())
                        }

                        it("routes to the list") {
                            let route = self.routeActionHandler.invokeArgument as! MainRouteAction
                            expect(route).to(equal(MainRouteAction.list))
                        }
                    }
                }

                describe("when not on the iPhone X") {
                    beforeEach {
                        self.view.iPhoneXStub = false
                        self.subject.onViewReady()
                    }

                    it("sets the appropriate content") {
                        expect(self.view.biometricImageName).to(equal("fingerprint-large"))
                        expect(self.view.biometricTitle).to(equal(Constant.string.onboardingTouchIDHeader))
                        expect(self.view.biometricSubTitle).to(equal(Constant.string.onboardingTouchIDSubtitle))
                    }

                    describe("enableTapped") {
                        beforeEach {
                            self.view.enableStub.onNext(())
                        }

                        it("sets the biometric login enabled & routes to the list") {
                            expect(self.settingActionHandler.actionArgument).to(equal(SettingAction.biometricLogin(enabled: true)))
                            let route = self.routeActionHandler.invokeArgument as! MainRouteAction
                            expect(route).to(equal(MainRouteAction.list))
                        }
                    }

                    describe("notNowTapped") {
                        beforeEach {
                            self.view.notNowStub.onNext(())
                        }

                        it("routes to the list") {
                            let route = self.routeActionHandler.invokeArgument as! MainRouteAction
                            expect(route).to(equal(MainRouteAction.list))
                        }
                    }
                }
            }
        }
    }
}

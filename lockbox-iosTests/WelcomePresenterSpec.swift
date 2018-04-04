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

                it("sets up the biometric image & text based on device capabilities") {
                    if LAContext.usesFaceID {
                        expect(self.view.biometricSignInTextStub.events.last!.value.element).to(equal(Constant.string.signInFaceID))
                        expect(self.view.biometricImageName.events.last!.value.element).to(equal("face"))
                    } else {
                        expect(self.view.biometricSignInTextStub.events.last!.value.element).to(equal(Constant.string.signInTouchID))
                        expect(self.view.biometricImageName.events.last!.value.element).to(equal("fingerprint"))
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

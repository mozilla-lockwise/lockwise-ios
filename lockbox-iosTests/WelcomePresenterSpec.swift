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
        var fakeFxAButtonPress = PublishSubject<Void>()
        var firstTimeMessageHiddenStub: TestableObserver<Bool>!
        var loginButtonHiddenStub: TestableObserver<Bool>!

        var loginButtonPressed: ControlEvent<Void> {
            return ControlEvent<Void>(events: fakeFxAButtonPress.asObservable())
        }

        var firstTimeLoginMessageHidden: AnyObserver<Bool> {
            return self.firstTimeMessageHiddenStub.asObserver()
        }

        var loginButtonHidden: AnyObserver<Bool> {
            return self.loginButtonHiddenStub.asObserver()
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeArgument = action
        }
    }

    class FakeDataStoreActionHandler: DataStoreActionHandler {
        var invokeArgument: DataStoreAction?

        override func invoke(_ action: DataStoreAction) {
            self.invokeArgument = action
        }
    }

    class FakeUserInfoStore: UserInfoStore {
        var fakeProfileInfo = PublishSubject<ProfileInfo?>()

        override var profileInfo: Observable<ProfileInfo?> {
            return self.fakeProfileInfo.asObservable()
        }
    }

    class FakeDataStore: DataStore {
        var fakeLocked = ReplaySubject<Bool>.create(bufferSize: 1)

        override var locked: Observable<Bool> {
            return self.fakeLocked.asObservable()
        }
    }

    class FakeBiometryManager: BiometryManager {
        var authMessage: String?
        var fakeAuthResponse = PublishSubject<Void>()

        override func authenticateWithMessage(_ message: String) -> Single<Void> {
            self.authMessage = message
            return fakeAuthResponse.take(1).asSingle()
        }
    }

    private var view: FakeWelcomeView!
    private var routeActionHandler: FakeRouteActionHandler!
    private var dataStoreActionHandler: FakeDataStoreActionHandler!
    private var userInfoStore: FakeUserInfoStore!
    private var dataStore: FakeDataStore!
    private var biometryManager: FakeBiometryManager!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: WelcomePresenter!

    override func spec() {

        describe("LoginPresenter") {
            beforeEach {
                self.view = FakeWelcomeView()
                self.view.firstTimeMessageHiddenStub = self.scheduler.createObserver(Bool.self)
                self.view.loginButtonHiddenStub = self.scheduler.createObserver(Bool.self)

                self.routeActionHandler = FakeRouteActionHandler()
                self.dataStoreActionHandler = FakeDataStoreActionHandler()
                self.userInfoStore = FakeUserInfoStore()
                self.dataStore = FakeDataStore()
                self.biometryManager = FakeBiometryManager()
                self.subject = WelcomePresenter(
                        view: self.view,
                        routeActionHandler: self.routeActionHandler,
                        dataStoreActionHandler: self.dataStoreActionHandler,
                        userInfoStore: self.userInfoStore,
                        dataStore: self.dataStore,
                        biometryManager: self.biometryManager
                )
            }

            describe("onViewReady") {
                describe("when the device is unlocked (first time login)") {
                    beforeEach {
                        self.dataStore.fakeLocked.onNext(false)
                        self.subject.onViewReady()
                    }

                    it("shows the first time login message and the fxa login button") {
                        expect(self.view.firstTimeMessageHiddenStub.events.last!.value.element).to(beFalse())
                        expect(self.view.loginButtonHiddenStub.events.last!.value.element).to(beFalse())
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

                describe("when the device is locked") {
                    let email = "butts@butts.com"

                    beforeEach {
                        self.dataStore.fakeLocked.onNext(true)
                        self.subject.onViewReady()
                        self.userInfoStore.fakeProfileInfo.onNext(ProfileInfo.Builder().email(email).build())
                    }

                    it("hides the first time login message and the fxa login button") {
                        expect(self.view.firstTimeMessageHiddenStub.events.last!.value.element).to(beTrue())
                        expect(self.view.loginButtonHiddenStub.events.last!.value.element).to(beTrue())
                    }

                    it("begins authentication with the profileInfo email") {
                        expect(self.biometryManager.authMessage).to(equal(email))
                    }

                    describe("successful authentication") {
                        beforeEach {
                            self.biometryManager.fakeAuthResponse.onNext(())
                        }

                        it("unlocks the application & routes to the list") {
                            expect(self.dataStoreActionHandler.invokeArgument).to(equal(DataStoreAction.unlock))
                            let argument = self.routeActionHandler.invokeArgument as! MainRouteAction
                            expect(argument).to(equal(MainRouteAction.list))
                        }
                    }

                    describe("unsuccessful authentication") {
                        beforeEach {
                            self.biometryManager.fakeAuthResponse.onError(NSError(domain: "localauthentication", code: -1))
                        }

                        it("does nothing") {
                            expect(self.routeActionHandler.invokeArgument).to(beNil())
                            expect(self.dataStoreActionHandler.invokeArgument).to(beNil())
                        }
                    }
                }
            }
        }
    }
}

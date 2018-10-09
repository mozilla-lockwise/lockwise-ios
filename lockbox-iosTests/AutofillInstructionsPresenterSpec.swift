/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class AutofillInstructionsPresenterSpec: QuickSpec {
    class FakeAutofillInstructionsView: AutofillInstructionsViewProtocol {
        let finishButtonTapStub = PublishSubject<Void>()

        var finishButtonTapped: Observable<Void> {
            return finishButtonTapStub.asObserver()
        }
    }

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    class FakeRouteStore: RouteStore {
        var isOnboardingValue = false
        override var onboarding: Observable<Bool> {
            return Observable.just(isOnboardingValue)
        }
    }

    private var routeStore: FakeRouteStore!
    private var view: FakeAutofillInstructionsView!
    private var dispatcher: FakeDispatcher!
    var subject: AutofillInstructionsPresenter!

    override func spec() {
        describe("AutofillInstrunctionsPresenter") {
            beforeEach {
                self.view = FakeAutofillInstructionsView()
                self.dispatcher = FakeDispatcher()
                self.routeStore = FakeRouteStore()
                self.subject = AutofillInstructionsPresenter(
                    view: self.view,
                    dispatcher: self.dispatcher,
                    routeStore: self.routeStore
                )
            }

            describe("onViewReady") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("onFinishButtonTapped") {
                    describe("during onboarding") {
                        beforeEach {
                            self.routeStore.isOnboardingValue = true
                            self.view.finishButtonTapStub.onNext(())
                        }

                        it("routes to the LoginRouteAction.onboardingConfirmation") {
                            let loginRouteAction = self.dispatcher.dispatchedActions.popLast() as! LoginRouteAction
                            expect(loginRouteAction).to(equal(.onboardingConfirmation))
                        }
                    }

                    describe("from settings") {
                        beforeEach {
                            self.routeStore.isOnboardingValue = false
                            self.view.finishButtonTapStub.onNext(())
                        }

                        it("routes to the SettingRouteAction.list") {
                            let settingRouteAction = self.dispatcher.dispatchedActions.popLast() as! SettingRouteAction
                            expect(settingRouteAction).to(equal(.list))
                        }
                    }
                }
            }
        }
    }
}

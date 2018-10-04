/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class AutofillOnboardingPresenterSpec: QuickSpec {

    class FakeAutofillOnboardingView: AutofillOnboardingViewProtocol {
        let skipButtonTapStub = PublishSubject<Void>()
        let setupAutofillTabStub = PublishSubject<Void>()

        var skipButtonTapped: Observable<Void> {
            return skipButtonTapStub.asObserver()
        }

        var setupAutofillTapped: Observable<Void> {
            return setupAutofillTabStub.asObserver()
        }
    }

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    private var view: FakeAutofillOnboardingView!
    private var dispatcher: FakeDispatcher!
    var subject: AutofillOnboardingPresenter!

    override func spec() {
        describe("AutofillOnboardingPresenter") {
            beforeEach {
                self.view = FakeAutofillOnboardingView()
                self.dispatcher = FakeDispatcher()
                self.subject = AutofillOnboardingPresenter(
                    view: self.view,
                    dispatcher: self.dispatcher
                )
            }

            describe("onViewReady") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("onSkipButtonTapped") {
                    beforeEach {
                        self.view.skipButtonTapStub.onNext(())
                    }

                    it("routes to the onboardingConfirmation") {
                        let loginRouteAction = self.dispatcher.dispatchedActions.popLast() as! LoginRouteAction
                        expect(loginRouteAction).to(equal(.onboardingConfirmation))
                    }
                }

                describe("onSetupAutofillTapped") {
                    beforeEach {
                        self.view.setupAutofillTabStub.onNext(())
                    }

                    it("routes to autofillInstructions") {
                        let loginRouteAction = self.dispatcher.dispatchedActions.popLast() as! LoginRouteAction
                        expect(loginRouteAction).to(equal(.autofillInstructions))
                    }
                }
            }
        }
    }
}

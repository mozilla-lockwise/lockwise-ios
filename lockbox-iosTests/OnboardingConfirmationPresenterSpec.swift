/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class OnboardingConfirmationPresenterSpec: QuickSpec {
    class FakeOnboardingConfView: OnboardingConfirmationViewProtocol {
        let finishTapStub = PublishSubject<Void>()

        var finishButtonTapped: Observable<Void> {
            return finishTapStub.asObservable()
        }
    }

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    private var view: FakeOnboardingConfView!
    private var dispatcher: FakeDispatcher!
    var subject: OnboardingConfirmationPresenter!

    override func spec() {
        describe("OnboardingConfirmationPresenter") {
            beforeEach {
                self.view = FakeOnboardingConfView()
                self.dispatcher = FakeDispatcher()
                self.subject = OnboardingConfirmationPresenter(
                        view: self.view,
                        dispatcher: self.dispatcher
                )
            }

            describe("onViewReady") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("onFinishButtonTapped") {
                    beforeEach {
                        self.view.finishTapStub.onNext(())
                    }

                    it("routes to the list and finishes onboarding") {
                        let onboardingStatusAction = self.dispatcher.dispatchedActions.popLast() as! OnboardingStatusAction
                        expect(onboardingStatusAction).to(equal(OnboardingStatusAction(onboardingInProgress: false)))

                        let mainRouteAction = self.dispatcher.dispatchedActions.popLast() as! MainRouteAction
                        expect(mainRouteAction).to(equal(.list))
                    }
                }
            }

            describe("onEncryptionLink") {
                beforeEach {
                    self.subject.onEncryptionLinkTapped()
                }

                it("routes to the external webview") {
                    let action = self.dispatcher.dispatchedActions.popLast() as! ExternalWebsiteRouteAction
                    expect(action).to(equal(
                            ExternalWebsiteRouteAction(
                                    urlString: Constant.app.securityFAQ,
                                    title: Localized.string.faq,
                                    returnRoute: LoginRouteAction.onboardingConfirmation)))
                }
            }
        }
    }
}

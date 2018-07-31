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
                        expect(self.dispatcher.dispatchedActions).to(haveCount(2))

                        expect(self.dispatcher.dispatchedActions[0]).to(beAnInstanceOf(MainRouteAction.self))
                        let mainRouteAction = self.dispatcher.dispatchedActions[0] as! MainRouteAction
                        expect(mainRouteAction).to(equal(.list))

                        expect(self.dispatcher.dispatchedActions[1]).to(beAnInstanceOf(OnboardingStatusAction.self))
                        let onboardingStatusAction = self.dispatcher.dispatchedActions[1] as! OnboardingStatusAction
                        expect(onboardingStatusAction).to(equal(OnboardingStatusAction(onboardingInProgress: false)))
                    }
                }
            }

            describe("onEncryptionLink") {
                beforeEach {
                    self.subject.onEncryptionLinkTapped()
                }

                it("routes to the external webview") {
                    expect(self.dispatcher.dispatchedActions).to(haveCount(1))
                    expect(self.dispatcher.dispatchedActions[0]).to(beAnInstanceOf(ExternalWebsiteRouteAction.self))
                    let action = self.dispatcher.dispatchedActions[0] as! ExternalWebsiteRouteAction
                    expect(action).to(equal(
                            ExternalWebsiteRouteAction(
                                    urlString: Constant.app.securityFAQ,
                                    title: Constant.string.faq,
                                    returnRoute: LoginRouteAction.onboardingConfirmation)))
                }
            }
        }
    }
}

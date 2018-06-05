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

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeArgument = action
        }
    }

    private var view: FakeOnboardingConfView!
    private var routeActionHandler: FakeRouteActionHandler!
    var subject: OnboardingConfirmationPresenter!

    override func spec() {
        describe("OnboardingConfirmationPresenter") {
            beforeEach {
                self.view = FakeOnboardingConfView()
                self.routeActionHandler = FakeRouteActionHandler()
                self.subject = OnboardingConfirmationPresenter(
                        view: self.view,
                        routeActionHandler: self.routeActionHandler
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

                    it("routes to the list") {
                        expect(self.routeActionHandler.invokeArgument).notTo(beNil())
                        let action = self.routeActionHandler.invokeArgument as! MainRouteAction
                        expect(action).to(equal(MainRouteAction.list))
                    }
                }
            }
        }
    }
}

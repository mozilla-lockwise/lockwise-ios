/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import Foundation
import RxSwift
import RxCocoa

@testable import Lockbox

class WelcomePresenterSpec: QuickSpec {
    class FakeWelcomeView: WelcomeViewProtocol {
        var fakeButtonPress = PublishSubject<Void>()
        var loginButtonPressed: ControlEvent<Void> {
            return ControlEvent<Void>(events: fakeButtonPress.asObservable())
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
    var subject: WelcomePresenter!

    override func spec() {

        describe("LoginPresenter") {
            beforeEach {
                self.view = FakeWelcomeView()
                self.routeActionHandler = FakeRouteActionHandler()
                self.subject = WelcomePresenter(view: self.view, routeActionHandler: self.routeActionHandler)

                self.subject.onViewReady()
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

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import WebKit
import RxCocoa
import RxSwift
import RxTest

@testable import Lockbox
import Account

class FxAPresenterSpec: QuickSpec {
    class FakeFxAView: FxAViewProtocol {
        var loadRequestArgument: URLRequest?

        func loadRequest(_ urlRequest: URLRequest) {
            self.loadRequestArgument = urlRequest
        }
    }

    class FakeNavigationAction: WKNavigationAction {
        private var fakeRequest: URLRequest
        override var request: URLRequest {
            return self.fakeRequest
        }

        init(request: URLRequest) {
            self.fakeRequest = request
        }
    }

    class FakeSettingActionHandler: SettingActionHandler {
        var invokeArgument: SettingAction?

        override func invoke(_ action: SettingAction) {
            self.invokeArgument = action
        }
    }

    class FakeDataStoreActionHandler: DataStoreActionHandler {
        var invokeArgument: DataStoreAction?

        override func invoke(_ action: DataStoreAction) {
            self.invokeArgument = action
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeArgument = action
        }
    }

    private var view: FakeFxAView!
    private var settingActionHandler: FakeSettingActionHandler!
    private var dataStoreActionHandler: FakeDataStoreActionHandler!
    private var routeActionHandler: FakeRouteActionHandler!
    var subject: FxAPresenter!

    override func spec() {

        describe("FxAPresenter") {
            beforeEach {
                self.view = FakeFxAView()
                self.settingActionHandler = FakeSettingActionHandler()
                self.dataStoreActionHandler = FakeDataStoreActionHandler()
                self.routeActionHandler = FakeRouteActionHandler()
                self.subject = FxAPresenter(
                        view: self.view,
                        settingActionHandler: self.settingActionHandler,
                        routeActionHandler: self.routeActionHandler,
                        dataStoreActionHandler: self.dataStoreActionHandler
                )
            }

            describe(".onViewReady()") {
                beforeEach {
                    self.subject.onViewReady()
                }

                it("tells the view to load the login URL") {
                    expect(self.view.loadRequestArgument?.url).to(equal(ProductionFirefoxAccountConfiguration().signInURL))
                }
            }

            describe("onClose") {
                beforeEach {
                    self.subject.onClose.onNext(())
                }

                it("routes back to login") {
                    expect(self.routeActionHandler.invokeArgument).notTo(beNil())
                    let argument = self.routeActionHandler.invokeArgument as! LoginRouteAction
                    expect(argument).to(equal(LoginRouteAction.welcome))
                }
            }
        }
    }
}

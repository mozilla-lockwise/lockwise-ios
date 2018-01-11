/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift

@testable import lockbox_ios

class RouteActionSpec : QuickSpec {
    class FakeDispatcher: Dispatcher {
        var actionTypeArgument: Action?

        override func dispatch(action: Action) {
            self.actionTypeArgument = action
        }
    }

    private var dispatcher:FakeDispatcher!

    override func spec() {
        describe("RouteActionHandler") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
            }

            describe("LoginRouteActionHandler") {
                var subject:LoginRouteActionHandler!
                beforeEach {
                    subject = LoginRouteActionHandler(dispatcher: self.dispatcher)
                }

                describe("invoke") {
                    beforeEach {
                        subject.invoke(LoginRouteAction.fxa)
                    }

                    it("dispatches actions to the dispatcher") {
                        expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                        let argument = self.dispatcher.actionTypeArgument as! LoginRouteAction
                        expect(argument).to(equal(LoginRouteAction.fxa))
                    }
                }
            }

            describe("MainRouteActionHandler") {
                var subject:MainRouteActionHandler!
                beforeEach {
                    subject = MainRouteActionHandler(dispatcher: self.dispatcher)
                }

                describe("invoke") {
                    beforeEach {
                        subject.invoke(MainRouteAction.list)
                    }

                    it("dispatches actions to the dispatcher") {
                        expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                        let argument = self.dispatcher.actionTypeArgument as! MainRouteAction
                        expect(argument).to(equal(MainRouteAction.list))
                    }
                }
            }
        }

        describe("MainRouteAction") {
            describe("equality") {
                it("listing is always equal") {
                    expect(MainRouteAction.list).to(equal(MainRouteAction.list))
                }

                it("detail view action is equal when the itemId is the same") {
                    let itemId = "fdjkfdsj"
                    expect(MainRouteAction.detail(itemId: itemId)).to(equal(MainRouteAction.detail(itemId: itemId)))
                }

                it("detail view action is not equal when the itemId is different") {
                    expect(MainRouteAction.detail(itemId: "dfsljkfsd")).notTo(equal(MainRouteAction.detail(itemId: "fsdsdf")))
                }

                it("detail action and list action are never equal") {
                    expect(MainRouteAction.detail(itemId: "sfddfs")).notTo(equal(MainRouteAction.list))
                }
            }
        }
    }
}
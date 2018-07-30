/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxCocoa
import Account
import FxAUtils

@testable import Lockbox

class AccountActionSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        var actionTypeArgument: Action?

        override func dispatch(action: Action) {
            self.actionTypeArgument = action
        }
    }

    private var dispatcher: FakeDispatcher!
    var subject: AccountActionHandler!

    override func spec() {
        describe("UserInfoActionHandler") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = AccountActionHandler(
                        dispatcher: self.dispatcher
                )
            }

            describe("invoke") {
                beforeEach {
                    self.subject.invoke(AccountAction.clear)
                }

                it("dispatches actions to the dispatcher") {
                    expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                    let argument = self.dispatcher.actionTypeArgument as! AccountAction
                    expect(argument).to(equal(AccountAction.clear))
                }
            }
        }

        describe("AccountAction") {
            describe("equality") {
                it("oauthRedirect actions are equal when the urls are equal") {
                    expect(AccountAction.oauthRedirect(url: URL(string: "www.mozilla.org")!)).to(equal(AccountAction.oauthRedirect(url: URL(string: "www.mozilla.org")!)))
                    expect(AccountAction.oauthRedirect(url: URL(string: "www.mozilla.org")!)).notTo(equal(AccountAction.oauthRedirect(url: URL(string: "www.mozilla.com")!)))
                }

                it("clear actions are always equal") {
                    expect(AccountAction.clear).to(equal(AccountAction.clear))
                }
            }
        }
    }
}

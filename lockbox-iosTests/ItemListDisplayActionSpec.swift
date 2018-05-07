/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift

@testable import Lockbox

class ItemListDisplayActionSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        var actionTypeArgument: Action?

        override func dispatch(action: Action) {
            self.actionTypeArgument = action
        }
    }

    private var dispatcher: FakeDispatcher!
    var subject: ItemListDisplayActionHandler!

    override func spec() {
        describe("RouteActionHandler") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = ItemListDisplayActionHandler(dispatcher: self.dispatcher)
            }

            describe("invoke") {
                beforeEach {
                    self.subject.invoke(ItemListSortingAction.recentlyUsed)
                }

                it("dispatches actions to the dispatcher") {
                    expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                    let argument = self.dispatcher.actionTypeArgument as! ItemListSortingAction
                    expect(argument).to(equal(ItemListSortingAction.recentlyUsed))
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Quick
import Nimble

@testable import Lockbox

class CopyActionSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        var dispatchedAction: Action?

        override func dispatch(action: Action) {
            self.dispatchedAction = action
        }
    }

    class FakePasteboard: UIPasteboard {
        var passedItems: [[String: Any]]?
        var options: [UIPasteboardOption: Any]?

        override func setItems(_ items: [[String: Any]], options: [UIPasteboardOption: Any]) {
            self.passedItems = items
            self.options = options
        }

    }

    private var dispatcher: FakeDispatcher!
    private var pasteboard: FakePasteboard!
    var subject: CopyActionHandler!

    override func spec() {
        describe("CopyActionHandler") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.pasteboard = FakePasteboard()

                self.subject = CopyActionHandler(
                        dispatcher: self.dispatcher,
                        pasteboard: self.pasteboard
                )
            }

            describe("invoke") {
                let text = "myspecialtext"
                let fieldName = "Password"
                let action = CopyAction(text: text, fieldName: fieldName)

                beforeEach {
                    self.subject.invoke(action)
                }

                it("add the item to the pasteboard with item and timeout option") {
                    let expireDate = Date().addingTimeInterval(TimeInterval(Constant.number.copyExpireTimeSecs))

                    expect(self.pasteboard.passedItems![0][UIPasteboardTypeAutomatic] as? String).to(equal(text))
                    expect(self.pasteboard.options![UIPasteboardOption.expirationDate] as! NSDate).to(beCloseTo(expireDate, within: 0.1))
                }

                it("dispatches the copied action") {
                    expect(self.dispatcher.dispatchedAction).notTo(beNil())
                    let copiedAction = self.dispatcher.dispatchedAction as! CopyConfirmationDisplayAction
                    expect(copiedAction).to(equal(CopyConfirmationDisplayAction(fieldName: fieldName)))
                }
            }
        }

        describe("CopyDisplayAction") {
            describe("equality") {
                it("CopyDisplayActions are equal when fieldnames are equal") {
                    expect(CopyConfirmationDisplayAction(fieldName: "something")).to(equal(CopyConfirmationDisplayAction(fieldName: "something")))
                    expect(CopyConfirmationDisplayAction(fieldName: "something")).notTo(equal(CopyConfirmationDisplayAction(fieldName: "not")))
                }
            }
        }

        describe("CopyAction") {
            describe("equality") {
                it("CopyActions are equal when fieldnames and text are equal") {
                    expect(CopyAction(text: "bleh", fieldName: "something")).to(equal(CopyAction(text: "bleh", fieldName: "something")))
                    expect(CopyAction(text: "murf", fieldName: "something")).notTo(equal(CopyAction(text: "bleh", fieldName: "something")))
                    expect(CopyAction(text: "bleh", fieldName: "something")).notTo(equal(CopyAction(text: "bleh", fieldName: "not")))
                    expect(CopyAction(text: "murf", fieldName: "something")).notTo(equal(CopyAction(text: "bleh", fieldName: "not")))
                }
            }
        }
    }
}

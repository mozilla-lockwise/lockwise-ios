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
        var newString: String?

        override var string: String? {
            get {
                return super.string
            }
            set {
                self.newString = newValue
            }
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

                it("copies the text to the pasteboard") {
                    expect(self.pasteboard.newString).to(equal(text))
                }

                it("dispatches the copied action") {
                    expect(self.dispatcher.dispatchedAction).notTo(beNil())
                    let copiedAction = self.dispatcher.dispatchedAction as! CopyDisplayAction
                    expect(copiedAction).to(equal(CopyDisplayAction(fieldName: fieldName)))
                }
            }
        }

        describe("CopyDisplayAction") {
            describe("equality") {
                it("CopyDisplayActions are equal when fieldnames are equal") {
                    expect(CopyDisplayAction(fieldName: "something")).to(equal(CopyDisplayAction(fieldName: "something")))
                    expect(CopyDisplayAction(fieldName: "something")).notTo(equal(CopyDisplayAction(fieldName: "not")))
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

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Quick
import Nimble

@testable import Firefox_Lockbox

class CopyActionSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
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
                let fieldName = CopyField.password
                let action = CopyAction(text: text, field: fieldName, itemID: "dsdfssd")

                beforeEach {
                    self.subject.invoke(action)
                }

                it("add the item to the pasteboard with item and timeout option") {
                    let expireDate = Date().addingTimeInterval(TimeInterval(Constant.number.copyExpireTimeSecs))

                    expect(self.pasteboard.passedItems![0][UIPasteboardTypeAutomatic] as? String).to(equal(text))
                    expect(self.pasteboard.options![UIPasteboardOption.expirationDate] as! NSDate).to(beCloseTo(expireDate, within: 0.1))
                }

                it("dispatches the copied action and the copy action") {
                    let copiedAction = self.dispatcher.dispatchedActions[0] as! CopyConfirmationDisplayAction
                    expect(copiedAction).to(equal(CopyConfirmationDisplayAction(field: .password)))

                    let copyAction = self.dispatcher.dispatchedActions[1] as! CopyAction
                    expect(copyAction).to(equal(action))
                }
            }
        }

        describe("CopyDisplayAction") {
            describe("equality") {
                it("CopyDisplayActions are equal when fieldnames are equal") {
                    expect(CopyConfirmationDisplayAction(field: CopyField.password)).to(equal(CopyConfirmationDisplayAction(field: CopyField.password)))
                    expect(CopyConfirmationDisplayAction(field: CopyField.password)).notTo(equal(CopyConfirmationDisplayAction(field: CopyField.username)))
                }
            }
        }

        describe("CopyAction") {
            describe("equality") {
                it("CopyActions are equal when fieldnames and text are equal") {
                    expect(CopyAction(text: "bleh", field: .username, itemID: "fdsfdsds")).to(equal(CopyAction(text: "bleh", field: .username, itemID: "fdsfdsds")))
                    expect(CopyAction(text: "murf", field: .password, itemID: "fdsfdsds")).notTo(equal(CopyAction(text: "bleh", field: .password, itemID: "fdsfdsds")))
                    expect(CopyAction(text: "bleh", field: .username, itemID: "fdsfdsds")).notTo(equal(CopyAction(text: "bleh", field: .password, itemID: "fdsfdsds")))
                    expect(CopyAction(text: "murf", field: .username, itemID: "fdsfdsds")).notTo(equal(CopyAction(text: "bleh", field: .password, itemID: "fdsfdsds")))
                }
            }

            describe("telemetry") {
                it("returns the tap event method") {
                    expect(CopyAction(text: "anything", field: .password, itemID: "fsdfsgfhgdfdfds").eventMethod).to(equal(TelemetryEventMethod.tap))
                }

                it("returns the button pressed as the object") {
                    expect(CopyAction(text: "anything", field: .password, itemID: "fsdfsgfhgdfdfds").eventObject).to(equal(TelemetryEventObject.entryCopyPasswordButton))
                    expect(CopyAction(text: "anything", field: .username, itemID: "fsdfsgfhgdfdfds").eventObject).to(equal(TelemetryEventObject.entryCopyUsernameButton))
                }
            }
        }
    }
}

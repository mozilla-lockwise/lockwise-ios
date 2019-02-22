/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Quick
import Nimble

@testable import Lockbox

class CopyActionSpec: QuickSpec {
    override func spec() {
        describe("CopyAction") {
            describe("equality") {
                it("CopyActions are equal when fieldnames, text, and action type are equal") {
                    expect(CopyAction(text: "bleh", field: .username, itemID: "fdsfdsds", actionType: .tap)).to(equal(CopyAction(text: "bleh", field: .username, itemID: "fdsfdsds", actionType: .tap)))
                    expect(CopyAction(text: "murf", field: .password, itemID: "fdsfdsds", actionType: .tap)).notTo(equal(CopyAction(text: "bleh", field: .password, itemID: "fdsfdsds", actionType: .tap)))
                    expect(CopyAction(text: "bleh", field: .username, itemID: "fdsfdsds", actionType: .tap)).notTo(equal(CopyAction(text: "bleh", field: .password, itemID: "fdsfdsds", actionType: .tap)))
                    expect(CopyAction(text: "murf", field: .username, itemID: "fdsfdsds", actionType: .tap)).notTo(equal(CopyAction(text: "bleh", field: .password, itemID: "fdsfdsds", actionType: .tap)))
                    expect(CopyAction(text: "murf", field: .username, itemID: "fdsfdsds", actionType: .dnd)).to(equal(CopyAction(text: "murf", field: .username, itemID: "fdsfdsds", actionType: .dnd)))
                    expect(CopyAction(text: "murf", field: .username, itemID: "fdsfdsds", actionType: .dnd)).notTo(equal(CopyAction(text: "murf", field: .username, itemID: "fdsfdsds", actionType: .tap)))
                }
            }

            describe("telemetry") {
                it("returns the tap event method") {
                    expect(CopyAction(text: "anything", field: .password, itemID: "fsdfsgfhgdfdfds", actionType: .tap).eventMethod).to(equal(TelemetryEventMethod.tap))
                }

                it("returns the dnd event method") {
                    expect(CopyAction(text: "anything", field: .password, itemID: "fsdfsgfhgdfdfds", actionType: .dnd).eventMethod).to(equal(TelemetryEventMethod.dnd))
                }

                it("returns the button pressed as the object") {
                    expect(CopyAction(text: "anything", field: .password, itemID: "fsdfsgfhgdfdfds", actionType: .tap).eventObject).to(equal(TelemetryEventObject.entryCopyPasswordButton))
                    expect(CopyAction(text: "anything", field: .username, itemID: "fsdfsgfhgdfdfds", actionType: .tap).eventObject).to(equal(TelemetryEventObject.entryCopyUsernameButton))
                }
            }
        }
    }
}

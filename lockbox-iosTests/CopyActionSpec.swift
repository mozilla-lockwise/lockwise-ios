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

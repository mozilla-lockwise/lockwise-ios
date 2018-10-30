/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Telemetry
import Quick
import Nimble
import RxSwift
import FxAClient

@testable import Lockbox

class TelemetryActionSpec: QuickSpec {
    class FakeTelemetry: Telemetry {
        var passedCategory: String?
        var passedMethod: String?
        var passedObject: String?
        var passedValue: String?

        var pingBuilder: TelemetryPingBuilder.Type?

        override func recordEvent(category: String, method: String, object: String, value: String?, extras: [String: Any?]?, pingType: String? = "default") {
            self.passedCategory = category
            self.passedMethod = method
            self.passedObject = object
            self.passedValue = value
        }
    }

    struct FakeTelemetryAction: TelemetryAction {
        var eventMethod: TelemetryEventMethod
        var eventObject: TelemetryEventObject
        var value: String?
        var extras: [String: Any?]?
    }

    private var telemetry: FakeTelemetry!
    private var accountStore: AccountStore!
    var subject: TelemetryActionHandler!

    override func spec() {
        describe("TelemetryActionHandler") {
            beforeEach {
                self.telemetry = FakeTelemetry(storageName: "meow")
                self.accountStore = AccountStore()
                self.subject = TelemetryActionHandler(telemetry: self.telemetry,
                                                      accountStore: self.accountStore)
            }

            describe("invoke") {
                let action = FakeTelemetryAction(
                        eventMethod: .tap,
                        eventObject: .entryList,
                        value: "meow",
                        extras: ["something": "blah", "something_else": nil, "third": 5]
                )

                beforeEach {
                    self.subject.telemetryActionListener.onNext(action)
                }

                it("records the event with telemetry") {
                    expect(self.telemetry.passedCategory).to(equal(TelemetryEventCategory.action.rawValue))
                    expect(self.telemetry.passedMethod).to(equal(action.eventMethod.rawValue))
                    expect(self.telemetry.passedObject).to(equal(action.eventObject.rawValue))
                    expect(self.telemetry.passedValue).to(equal(action.value))
                }
            }
        }
    }
}

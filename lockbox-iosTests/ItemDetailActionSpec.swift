/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift

@testable import Lockbox

class ItemDetailActionSpec: QuickSpec {

    class FakeDispatcher: Dispatcher {
        var dispatchedAction: Action?

        override func dispatch(action: Action) {
            self.dispatchedAction = action
        }
    }

    private var dispatcher: FakeDispatcher!

    override func spec() {

        describe("ItemDetailDisplayAction equality") {
            it("togglepassword is equal based on the bool value") {
                expect(ItemDetailDisplayAction.togglePassword(displayed: true))
                        .to(equal(ItemDetailDisplayAction.togglePassword(displayed: true)))
                expect(ItemDetailDisplayAction.togglePassword(displayed: true))
                        .notTo(equal(ItemDetailDisplayAction.togglePassword(displayed: false)))
            }
        }

        describe("telemetry") {
            it("event method should equal tap") {
                expect(ItemDetailDisplayAction.togglePassword(displayed: true).eventMethod).to(equal(TelemetryEventMethod.tap))
            }

            it("event object should equal revealPassword") {
                expect(ItemDetailDisplayAction.togglePassword(displayed: true).eventObject).to(equal(TelemetryEventObject.revealPassword))
            }
        }

        describe("ItemEditAction equality") {
            it("editUsername is equal for same username") {
                expect(ItemEditAction.editUsername(value: "a")).to(equal(ItemEditAction.editUsername(value: "a")))
            }

            it("editUsername is not equal for different usernames") {
                expect(ItemEditAction.editUsername(value: "a")).to(equal(ItemEditAction.editUsername(value: "a")))
            }

            it("editPassword is equal for same username") {
                expect(ItemEditAction.editPassword(value: "a")).to(equal(ItemEditAction.editPassword(value: "a")))
            }

            it("editPassword is not equal for different usernames") {
                expect(ItemEditAction.editPassword(value: "a")).notTo(equal(ItemEditAction.editPassword(value: "b")))
            }

            it("editWebAddress is equal for same username") {
                expect(ItemEditAction.editWebAddress(value: "a")).to(equal(ItemEditAction.editWebAddress(value: "a")))
            }

            it("editWebAddress is not equal for different usernames") {
                expect(ItemEditAction.editWebAddress(value: "a")).notTo(equal(ItemEditAction.editWebAddress(value: "b")))
            }

            it("editUsername does not equal editPassword") {
                expect(ItemEditAction.editUsername(value: "a")).notTo(equal(ItemEditAction.editPassword(value: "a")))
            }

            it("editUsername does not equal editWebAddress") {
                expect(ItemEditAction.editUsername(value: "a")).notTo(equal(ItemEditAction.editWebAddress(value: "a")))
            }

            it("editPassword does not equal editWebAddress") {
                expect(ItemEditAction.editPassword(value: "a")).notTo(equal(ItemEditAction.editWebAddress(value: "a")))
            }
        }
    }
}

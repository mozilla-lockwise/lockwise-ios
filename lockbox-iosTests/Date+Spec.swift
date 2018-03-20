/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

class DateSpec: QuickSpec {
    override func spec() {
        describe(".iso8601DateString initializer") {
            it("gives the correct date when provided with a string with fractional seconds") {
                expect(Date(iso8601DateString: "1970-01-01T00:03:20.4500Z")).to(equal(Date.init(timeIntervalSince1970: 200)))
            }

            it("returns nil if the string is not a valid ISO8601 string") {
                expect(Date(iso8601DateString: "")).to(beNil())
            }
        }
    }
}

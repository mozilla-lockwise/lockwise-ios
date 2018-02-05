/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import Foundation

@testable import Lockbox

class ProfileInfoSpec: QuickSpec {
    override func spec() {
        describe("builder") {
            it("builds the ProfileInfo with all the provided parameters") {
                let uid = "something"
                let email = "something@something.com"

                let info = ProfileInfo.Builder()
                        .uid(uid)
                        .email(email)
                        .build()

                expect(info.uid).to(equal(uid))
                expect(info.email).to(equal(email))
            }
        }
    }
}

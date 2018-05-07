/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Quick
import Nimble

@testable import Firefox_Lockbox

class UIColorSpec: QuickSpec {
    override func spec() {
        describe("UIColor") {
            describe("hex init") {
                it("works") {
                    expect(UIColor(hex: 0xFFFFFF)).to(equal(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
                }
            }

            describe("RGB convenience init") {
                it("works") {
                    expect(UIColor(red: 255, green: 255, blue: 255)).to(equal(UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)))
                }
            }
        }
    }
}

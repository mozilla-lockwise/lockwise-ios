/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class AdjustManagerSpec: QuickSpec {
    private var subject: AdjustManager!

    override func spec() {
        describe("AdjustManager") {
            beforeEach {
                self.subject = AdjustManager()
            }

            // Disabling as they seem to fail on buddybuild: GH Issue #787
            xdescribe("set enable to true") {
                beforeEach {
                    self.subject.setEnabled(true)
                }

                it("enables adjust") {
                    expect(self.subject.adjust.isEnabled()).toEventually(beTrue())
                }
            }

            xdescribe("set enable to false") {
                beforeEach {
                    self.subject.setEnabled(false)
                }

                it("disables adjust") {
                    expect(self.subject.adjust.isEnabled()).toEventually(beFalse())
                }
            }
        }
    }
}

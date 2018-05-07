/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Quick
import Nimble

@testable import Firefox_Lockbox

class LoginNavigationControllerSpec: QuickSpec {
    var subject: LoginNavigationController!

    override func spec() {
        describe("LoginNavigationController") {
            beforeEach {
                self.subject = LoginNavigationController()
            }

            it("sets a LoginView as the root view controller") {
                expect(self.subject.viewControllers.first).to(beAnInstanceOf(WelcomeView.self))
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import LocalAuthentication

@testable import Lockbox

class LAContextSpec: QuickSpec {
    override func spec() {
        it("usesFaceID") {
            let authContext = LAContext()

            var error: NSError?
            if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                if #available(iOS 11.0, *) {
                    expect(LAContext.usesFaceId).to(beTrue())
                } else {
                    expect(LAContext.usesFaceId).to(beFalse())
                }
            } else {
                expect(LAContext.usesFaceId).to(beFalse())
            }
        }
    }
}

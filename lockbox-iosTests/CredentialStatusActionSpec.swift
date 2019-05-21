/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import MozillaAppServices
import AuthenticationServices

@testable import Lockbox

@available(iOS 12.0, *)
class CredentialStatusActionSpec: QuickSpec {
    override func spec() {
        describe("CredentialStatusAction") {
            describe("equality") {
                it("extensionConfigured is always equal") {
                    expect(CredentialStatusAction.extensionConfigured).to(equal(CredentialStatusAction.extensionConfigured))
                }

                it("userCancelled is always equal") {
                    expect(CredentialStatusAction.cancelled(error: .failed)).to(equal(CredentialStatusAction.cancelled(error: .failed)))
                }

                it("loginSelected is equalbased on login and relock values") {
                    let login1 = LoginRecord(fromJSONDict: ["id": "fasasdf", "hostname": "www.mozilla.com", "username": "dogs@dogs.com", "password": "meow"])
                    let login2 = LoginRecord(fromJSONDict: ["id": ";l;iiojlkljk", "hostname": "www.neopets.com", "username": "cats@cats.com", "password": "woof"])

                    expect(CredentialStatusAction.loginSelected(login: login1)).to(equal(CredentialStatusAction.loginSelected(login: login1)))
                    expect(CredentialStatusAction.loginSelected(login: login2)).notTo(equal(CredentialStatusAction.loginSelected(login: login1)))
                }

                it("different enum values are not equal") {
                    expect(CredentialStatusAction.cancelled(error: .userCanceled)).notTo(equal(CredentialStatusAction.extensionConfigured))
                }
            }

            describe("telemetry") {
                it("returns the settingChanged event method") {
                    expect(CredentialStatusAction.extensionConfigured.eventMethod).to(equal(TelemetryEventMethod.settingChanged))
              }
            }
        }
    }
}

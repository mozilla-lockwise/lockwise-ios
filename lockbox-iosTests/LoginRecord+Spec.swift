/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Logins
import AuthenticationServices
import Quick
import Nimble

@testable import Lockbox

@available(iOS 12, *)
class LoginRecordSpec: QuickSpec {
    override func spec() {
        describe("Login+") {
            let guid = "fsdsdf"
            let hostname = "http://www.mozilla.org"
            let username = "dogs@dogs.com"
            let password = "iluvcatz"
            let login = LoginRecord(fromJSONDict: ["id": guid, "hostname": hostname, "username": username, "password": password])

            describe("passwordCredentialIdentity") {
                it("makes a credential identity with the login parameters") {
                    expect(login.passwordCredentialIdentity.recordIdentifier).to(equal(guid))
                    expect(login.passwordCredentialIdentity.user).to(equal(username))
                    expect(login.passwordCredentialIdentity.serviceIdentifier.identifier).to(equal(hostname))
                }
            }

            describe("passwordCredential") {
                it("makes a password credential with the login parameters") {
                    expect(login.passwordCredential.user).to(equal(username))
                    expect(login.passwordCredential.password).to(equal(password))
                }
            }
        }
    }
}

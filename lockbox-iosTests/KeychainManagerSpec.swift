/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

class KeychainManagerSpec: QuickSpec {

    var subject: KeychainManager!

    override func spec() {
        describe("KeychainManager") {
            beforeEach {
                self.subject = KeychainManager()
            }

            describe("saving a string") {
                let email = "doggo@mozilla.com"

                it("saves the string to the keychain") {
                    expect(self.subject.save(email, identifier: .email)).to(beTrue())

                    let query: [String: Any] = [
                        kSecAttrService as String: Bundle.main.bundleIdentifier!,
                        kSecAttrAccount as String: "email",
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrSynchronizable as String: kCFBooleanFalse,
                        kSecMatchLimit as String: kSecMatchLimitOne,
                        kSecReturnData as String: true
                    ]
                    var item: AnyObject?
                    let status = withUnsafeMutablePointer(to: &item) {
                        SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
                    }

                    guard status == noErr,
                          let emailData = item as? Data,
                          let storedEmail = String(data: emailData, encoding: .utf8) else {
                        fail("Item not found in correct format")
                        abort()
                    }

                    expect(storedEmail).to(equal(email))
                }

                describe("updating the string") {
                    let newEmail = "dogzone@mozilla.com"

                    it("updates the string in the keychain") {
                        expect(self.subject.save(newEmail, identifier: .email)).to(beTrue())

                        let query: [String: Any] = [
                            kSecAttrService as String: Bundle.main.bundleIdentifier!,
                            kSecAttrAccount as String: "email",
                            kSecClass as String: kSecClassGenericPassword,
                            kSecAttrSynchronizable as String: kCFBooleanFalse,
                            kSecMatchLimit as String: kSecMatchLimitOne,
                            kSecReturnData as String: true
                        ]
                        var item: AnyObject?
                        let status = withUnsafeMutablePointer(to: &item) {
                            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
                        }

                        guard status == noErr,
                              let emailData = item as? Data,
                              let storedEmail = String(data: emailData, encoding: .utf8) else {
                            fail("Item not found in correct format")
                            abort()
                        }

                        expect(storedEmail).to(equal(newEmail))
                    }

                    it("replaces the string in the keychain if the value is the same") {
                        expect(self.subject.save(email, identifier: .email)).to(beTrue())

                        let query: [String: Any] = [
                            kSecAttrService as String: Bundle.main.bundleIdentifier!,
                            kSecAttrAccount as String: "email",
                            kSecClass as String: kSecClassGenericPassword,
                            kSecAttrSynchronizable as String: kCFBooleanFalse,
                            kSecMatchLimit as String: kSecMatchLimitOne,
                            kSecReturnData as String: true
                        ]
                        var item: AnyObject?
                        let status = withUnsafeMutablePointer(to: &item) {
                            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
                        }

                        guard status == noErr,
                              let emailData = item as? Data,
                              let storedEmail = String(data: emailData, encoding: .utf8) else {
                            fail("Item not found in correct format")
                            abort()
                        }

                        expect(storedEmail).to(equal(email))
                    }
                }

                describe("deleting the string") {
                    it("removes the string from the keychain") {
                        expect(self.subject.save(email, identifier: .email)).to(beTrue())

                        expect(self.subject.delete(.email)).to(beTrue())

                        let query: [String: Any] = [
                            kSecAttrService as String: Bundle.main.bundleIdentifier!,
                            kSecAttrAccount as String: "email",
                            kSecClass as String: kSecClassGenericPassword,
                            kSecAttrSynchronizable as String: kCFBooleanFalse,
                            kSecMatchLimit as String: kSecMatchLimitOne,
                            kSecReturnData as String: true
                        ]
                        var item: AnyObject?
                        let status = withUnsafeMutablePointer(to: &item) {
                            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
                        }

                        expect(status).notTo(equal(noErr))
                    }
                }
            }

            describe("retrieving a string") {
                describe("when the string has not previously been saved") {
                    it("returns nil") {
                        expect(self.subject.retrieve(.scopedKey)).to(beNil())
                    }
                }

                describe("when the string has previously been saved") {
                    let email = "doggo@mozilla.com"

                    it("retrieves the saved value successfully") {
                        expect(self.subject.save(email, identifier: .email)).to(beTrue())
                        expect(self.subject.retrieve(.email)).to(equal(email))
                    }
                }
            }
        }
    }
}

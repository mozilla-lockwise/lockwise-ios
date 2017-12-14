/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import lockbox_ios

class KeychainManagerSpec : QuickSpec {

    var subject:KeychainManager!

    override func spec() {
        describe("KeychainManager") {
            beforeEach {
                self.subject = KeychainManager()
            }

            describe("saving an email") {
                let email = "doggo@mozilla.com"
                beforeEach {
                    self.subject.saveUserEmail(email)
                }

                it("saves the email to the keychain") {
                    let query:[String:Any] = [
                        kSecAttrService as String: Bundle.main.bundleIdentifier!,
                        kSecAttrAccount as String: "email",
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrSynchronizable as String: kCFBooleanFalse,
                        kSecMatchLimit as String: kSecMatchLimitOne,
                        kSecReturnData as String: true,
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

            describe("saving a scoped key") {
                let key = "sdfkljafsdlkhjfdsahjksdfjkladfsmn,basdfhjklzxdjkldsa"
                beforeEach {
                    self.subject.saveScopedKey(key)
                }

                it("saves the key to the keychain") {

                    let query:[String:Any] = [
                        kSecAttrService as String: Bundle.main.bundleIdentifier!,
                        kSecAttrAccount as String: "scopedKey",
                        kSecClass as String: kSecClassGenericPassword,
                        kSecAttrSynchronizable as String: kCFBooleanFalse,
                        kSecMatchLimit as String: kSecMatchLimitOne,
                        kSecReturnData as String: true,
                    ]
                    var item: AnyObject?
                    let status = withUnsafeMutablePointer(to: &item) {
                        SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
                    }

                    guard status == noErr,
                          let scopedKeyData = item as? Data,
                          let storedKey = String(data: scopedKeyData, encoding: .utf8) else {
                        fail("Item not found in correct format")
                        abort()
                    }

                    expect(storedKey).to(equal(key))
                }
            }
        }
    }
}
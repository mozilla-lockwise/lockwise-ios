/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Security

enum KeychainManagerKey: String {
    case email, scopedKey, uid
}

class KeychainManager {
    @discardableResult
    func saveUserEmail(_ email: String) -> Bool {
        let emailData = Data(email.utf8)

        let attributes:[String:Any] = [
            kSecAttrAccount as String: KeychainManagerKey.email.rawValue,
            kSecAttrService as String: Bundle.main.bundleIdentifier!,
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: kCFBooleanFalse,
            kSecValueData as String: emailData,
        ]

        let success = SecItemAdd(attributes as CFDictionary, nil)

        return success == noErr
    }

    @discardableResult
    func saveScopedKey(_ key:String) -> Bool {
        let keyData = Data(key.utf8)

        let attributes:[String:Any] = [
            kSecAttrAccount as String: KeychainManagerKey.scopedKey.rawValue,
            kSecAttrService as String: Bundle.main.bundleIdentifier!,
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: kCFBooleanFalse,
            kSecValueData as String: keyData,
        ]

        let success = SecItemAdd(attributes as CFDictionary, nil)

        return success == noErr
    }

    @discardableResult
    func saveFxAUID(_ uid:String) -> Bool {
        let keyData = Data(uid.utf8)

        let attributes:[String:Any] = [
            kSecAttrAccount as String: KeychainManagerKey.uid.rawValue,
            kSecAttrService as String: Bundle.main.bundleIdentifier!,
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: kCFBooleanFalse,
            kSecValueData as String: keyData,
        ]

        let success = SecItemAdd(attributes as CFDictionary, nil)

        return success == noErr
    }
}

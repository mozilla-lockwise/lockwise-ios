/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Security

enum KeychainManagerService: String {
    case FxA
}

enum KeychainManagerKey: String {
    case email, scopedKey
}

class KeychainManager {
    @discardableResult
    func saveUserEmail(_ email: String, service:KeychainManagerService) -> Bool {
        let emailData = Data(email.utf8)

        let attributes:[String:Any] = [
            kSecAttrAccount as String: prefixedKey(.email),
            kSecAttrService as String: service.rawValue,
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: kCFBooleanFalse,
            kSecValueData as String: emailData,
        ]

        let success = SecItemAdd(attributes as CFDictionary, nil)

        return success == noErr
    }

    @discardableResult
    func saveScopedKey(_ key:String, service:KeychainManagerService) -> Bool {
        let keyData = Data(key.utf8)

        let attributes:[String:Any] = [
            kSecAttrAccount as String: prefixedKey(.scopedKey),
            kSecAttrService as String: service.rawValue,
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: kCFBooleanFalse,
            kSecValueData as String: keyData,
        ]

        let success = SecItemAdd(attributes as CFDictionary, nil)

        return success == noErr
    }

    private func prefixedKey(_ key:KeychainManagerKey) -> String {
        return Bundle.main.bundleIdentifier! + key.rawValue
    }
}

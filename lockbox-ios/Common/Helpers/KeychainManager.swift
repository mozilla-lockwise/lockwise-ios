/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Security

enum KeychainManagerIdentifier: String {
    case email, scopedKey, uid, refreshToken, accessToken, idToken, avatarURL, biometricLoginEnabled

    static let allValues: [KeychainManagerIdentifier] = [
        .email,
        .scopedKey,
        .uid,
        .refreshToken,
        .accessToken,
        .idToken,
        .avatarURL,
        .biometricLoginEnabled
    ]
}

class KeychainManager {
    func save(_ data: String, identifier: KeychainManagerIdentifier) -> Bool {
        guard let savedItem = self.retrieve(identifier) else {
            return self.saveByAdding(data, identifier: identifier)
        }

        if savedItem == data {
            return true
        }

        return self.saveByUpdating(data, identifier: identifier)
    }

    func retrieve(_ identifier: KeychainManagerIdentifier) -> String? {
        let query: [String: Any] = [
            kSecAttrService as String: Bundle.main.bundleIdentifier!,
            kSecAttrAccount as String: identifier.rawValue,
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
              let data = item as? Data,
              let storedString = String(data: data, encoding: .utf8) else {
            return nil
        }

        return storedString
    }

    func delete(_ identifier: KeychainManagerIdentifier) -> Bool {
        let query: [String: Any] = [
            kSecAttrService as String: Bundle.main.bundleIdentifier!,
            kSecAttrAccount as String: identifier.rawValue,
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: kCFBooleanFalse
        ]

        let status = SecItemDelete(query as CFDictionary)

        return status == errSecSuccess
    }

    private func saveByAdding(_ data: String, identifier: KeychainManagerIdentifier) -> Bool {
        let attributes: [String: Any] = [
            kSecAttrAccount as String: identifier.rawValue,
            kSecAttrService as String: Bundle.main.bundleIdentifier!,
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: kCFBooleanFalse,
            kSecValueData as String: Data(data.utf8)
        ]

        let success = SecItemAdd(attributes as CFDictionary, nil)
        return success == noErr
    }

    private func saveByUpdating(_ data: String, identifier: KeychainManagerIdentifier) -> Bool {
        let query: [String: Any] = [
            kSecAttrService as String: Bundle.main.bundleIdentifier!,
            kSecAttrAccount as String: identifier.rawValue,
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrSynchronizable as String: kCFBooleanFalse
        ]

        let update: [String: Any] = [
            kSecValueData as String: Data(data.utf8)
        ]

        let success = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        return success == noErr
    }
}

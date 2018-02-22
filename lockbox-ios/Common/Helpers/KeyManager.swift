/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import CJose
import Foundation

class KeyManager {
    private var jwk: OpaquePointer?

    func getEphemeralPublicECDH() -> String {
        if self.jwk == nil {
            self.jwk = cjose_jwk_create_EC_random(CJOSE_JWK_EC_P_256, nil)
        }

        let jsonValue = cjose_jwk_to_json(self.jwk!, false, nil)

        return String(cString: jsonValue!)
    }

    func decryptJWE(_ jwe: String) -> String? {
        let count = jwe.data(using: .utf8)!.count as size_t
        let contentLen = UnsafeMutablePointer<size_t>.allocate(capacity: count)
        let err = UnsafeMutablePointer<cjose_err>.allocate(capacity: count)

        let cJoseJWE = cjose_jwe_import(jwe, count, nil)
        guard let decryptedPayload = cjose_jwe_decrypt(cJoseJWE, self.jwk, contentLen, err) else {
            return nil
        }

        return String(bytesNoCopy: decryptedPayload, length: contentLen.pointee, encoding: .utf8, freeWhenDone: true)
    }

    func random32() -> Data? {
        var d = Data(count: 32)
        let result = d.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, d.count, $0)
        }
        if result == errSecSuccess {
            return d
        } else {
            return nil
        }
    }
}

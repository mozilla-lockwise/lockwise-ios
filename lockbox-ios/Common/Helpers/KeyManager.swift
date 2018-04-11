/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import CJose
import Foundation

struct KeyManagerError: Error {
    let message: String
}

class KeyManager {
    private var jwk: OpaquePointer?
    lazy private var err = UnsafeMutablePointer<cjose_err>.allocate(capacity: self.errSize)
    lazy private var errSize = MemoryLayout<cjose_err>.size
    lazy private var sizeTSize = MemoryLayout<size_t>.size

    private var errorMessage: String {
        return String(cString: self.err.pointee.message)
    }

    func getEphemeralPublicECDH() throws -> String {
        if self.jwk == nil {
            self.jwk = cjose_jwk_create_EC_random(CJOSE_JWK_EC_P_256, self.err)
        }

        guard let jwk = self.jwk,
              let jsonValue = cjose_jwk_to_json(jwk, false, self.err) else {
            throw KeyManagerError(message: self.errorMessage)
        }

        return String(cString: jsonValue)
    }

    func decryptJWE(_ jwe: String) throws -> String {
        let count = jwe.data(using: .utf8)!.count as size_t

        guard let cJoseJWE = cjose_jwe_import(jwe, count, self.err) else {
            throw KeyManagerError(message: self.errorMessage)
        }

        let contentLen = UnsafeMutablePointer<size_t>.allocate(capacity: self.sizeTSize)
        guard let decryptedPayload = cjose_jwe_decrypt(cJoseJWE, self.jwk, contentLen, self.err) else {
            cjose_jwe_release(cJoseJWE)
            contentLen.deallocate()
            throw KeyManagerError(message: self.errorMessage)
        }

        cjose_jwe_release(cJoseJWE)

        guard let decryptedJWEString = String(
                bytesNoCopy: decryptedPayload,
                length: contentLen.pointee,
                encoding: .utf8,
                freeWhenDone: true) else {
            contentLen.deallocate()
            throw KeyManagerError(message: "Unable to import decrypted payload")
        }

        contentLen.deallocate()
        return decryptedJWEString
    }

    func random32() -> Data? {
        let dCount = 32
        var d = Data(count: dCount)
        let result = d.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, dCount, $0)
        }
        if result == errSecSuccess {
            return d
        } else {
            return nil
        }
    }

    deinit {
        self.err.deallocate()

        guard let jwk = self.jwk else {
            return
        }
        cjose_jwk_release(jwk)
    }
}

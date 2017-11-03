/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import CJose

class KeyManager {
    private var jwk:OpaquePointer?

    func generateRandomECDH() -> String {
        self.jwk = cjose_jwk_create_EC_random(CJOSE_JWK_EC_P_256, nil)

        let jsonValue = cjose_jwk_to_json(self.jwk!, false, nil)

        return String(cString: jsonValue!)
    }

    func decryptJWE(_ jwe: String) -> String {
        let decryptedPayload = cjose_jwe_decrypt(cjose_jwe_import(jwe, jwe.count, nil), self.jwk, nil, nil)

        return String(cString: decryptedPayload!)
    }
}


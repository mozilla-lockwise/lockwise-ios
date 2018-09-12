/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension String {
    func base64URL() -> String {
        return Data(self.utf8).base64URLEncodedString()
    }

    func sha256withBase64URL() -> String? {
        guard let data = self.data(using: String.Encoding.utf8),
              let shaData = sha256(data)
                else { return nil }
        return shaData.base64URLEncodedString()
    }

    func titleFromHostname() -> String {
        return self
                .replacingOccurrences(of: "^http://", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^https://", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^www\\d*\\.", with: "", options: .regularExpression)
    }

    private func sha256(_ data: Data) -> Data? {
        guard let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH)) else { return nil }
        CC_SHA256((data as NSData).bytes, CC_LONG(data.count), res.mutableBytes.assumingMemoryBound(to: UInt8.self))
        return res as Data
    }
}

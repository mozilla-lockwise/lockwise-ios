/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import CJose

@testable import Lockbox

class KeyManagerSpec: QuickSpec {
    var subject: KeyManager!
    var key: String!

    override func spec() {
        beforeEach {
            self.subject = KeyManager()
            self.key = try! self.subject.getEphemeralPublicECDH()
        }

        describe(".getEphemeralPublicECDH()") {
            it("generates an ECDH public-key JSON string with correct parameters & data sizes") {
                if let data = self.key.data(using: .utf8) {
                    do {
                        let jsonDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]

                        expect(jsonDict!["kty"]).to(equal("EC"))
                        expect(jsonDict!["crv"]).to(equal("P-256"))
                        expect(jsonDict!["x"]!.count).to(equal(43))
                        expect(jsonDict!["y"]!.count).to(equal(43))
                    } catch {
                        fail("key generation not provided in json dictionary format!")
                    }
                }
            }

            it("caches the ECDH key and returns the same one on subsequent requests") {
                let secondKey = try! self.subject.getEphemeralPublicECDH()

                if let keyOneData = self.key.data(using: .utf8), let keyTwoData = secondKey.data(using: .utf8) {
                    do {
                        let keyOneJSONDict = try JSONSerialization.jsonObject(
                                with: keyOneData, options: []
                        ) as? [String: String]
                        let keyTwoJSONDict = try JSONSerialization.jsonObject(
                                with: keyTwoData, options: []
                        ) as? [String: String]

                        expect(keyOneJSONDict!["kty"]).to(equal(keyTwoJSONDict!["kty"]))
                        expect(keyOneJSONDict!["crv"]).to(equal(keyTwoJSONDict!["crv"]))
                        expect(keyOneJSONDict!["x"]!).to(equal(keyTwoJSONDict!["x"]!))
                        expect(keyOneJSONDict!["y"]!).to(equal(keyTwoJSONDict!["y"]!))
                    } catch {
                        fail("key generation not provided in json dictionary format!")
                    }
                }
            }
        }

        describe(".decryptJWE()") {
            describe("when the JWE is not formatted correctly") {
                it("throws an error") {
                    expect {
                        try self.subject.decryptJWE("")
                    }.to(throwError())
                }
            }

            describe("when the JWE is formatted correctly") {
                let payload = "some data I put in here"
                var serializedJWE: String!

                beforeEach {
                    let count = self.key.data(using: .utf8)!.count as size_t
                    let jwkFromJSON = cjose_jwk_import(self.key, count, nil)

                    let cjoseError = UnsafeMutablePointer<cjose_err>.allocate(capacity: count)
                    let header: OpaquePointer = cjose_header_new(nil)
                    cjose_header_set(header, CJOSE_HDR_ALG, CJOSE_HDR_ALG_ECDH_ES, nil)
                    cjose_header_set(header, CJOSE_HDR_ENC, CJOSE_HDR_ENC_A256GCM, nil)

                    let jwe = cjose_jwe_encrypt(jwkFromJSON,
                            header,
                            payload,
                            payload.count,
                            cjoseError)
                    serializedJWE = String(cString: cjose_jwe_export(jwe, nil))
                }

                describe("when the payload cannot be decrypted") {
                    beforeEach {
                        // munge last three characters of JWE encoding
                        serializedJWE = "\(serializedJWE[..<serializedJWE.index(serializedJWE.endIndex, offsetBy: -3)])"
                        serializedJWE.append("sss")
                    }

                    it("throws an error") {
                        expect {
                            try self.subject.decryptJWE(serializedJWE)
                        }.to(throwError())
                    }
                }

                describe("when the payload can be decrypted") {
                    it("decrypts a provided JWE payload") {
                        expect(try! self.subject.decryptJWE(serializedJWE)).to(equal(payload))
                    }
                }
            }
        }

        describe(".random32") {
            it("generates a 32-byte piece of data") {
                let random = self.subject.random32()!
                expect(random.count).to(equal(32))
            }

            it("does not generate the same string over multiple calls") {
                // note: randomness is tricky to test...
                expect(self.subject.random32()!).notTo(equal(self.subject.random32()!))
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import Foundation

@testable import lockbox_ios

class StringSpec : QuickSpec {
    override func spec() {
        let subject = "a pretty long string that we're going to encode yep yep yep!"

        describe(".base64URL") {
            it("encodes the string in base64URL") {
                expect(subject.base64URL()).to(equal("YSBwcmV0dHkgbG9uZyBzdHJpbmcgdGhhdCB3ZSdyZSBnb2luZyB0byBlbmNvZGUgeWVwIHllcCB5ZXAh"))
            }
        }

        describe(".sha256withBase64URL") {
            it("hashes the string to sha256 and encodes as a base64URL") {
                expect(subject.sha256withBase64URL()).to(equal("sQso4JtDJmbacP2IVO2N73-OmbJL5h-GGkeWOjQSbgg"))
            }
        }
    }
}
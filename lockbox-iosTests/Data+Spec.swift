/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import Foundation
import RxSwift
import RxBlocking

@testable import Lockbox

class DataSpec: QuickSpec {

    override func spec() {
        let subject = Data("a pretty long string that we're going to encode yep yep yep".utf8)

        describe(".base64URLEncoded") {
            let base64Encoded = subject.base64EncodedString()
            let base64URLEncoded = subject.base64URLEncodedString()

            it("replaces the relevant characters from the provided base64Encoding method") {
                expect(base64Encoded).notTo(equal(base64URLEncoded))
                expect(base64URLEncoded).to(equal("YSBwcmV0dHkgbG9uZyBzdHJpbmcgdGhhdCB3ZSdyZSBnb2luZyB0byBlbmNvZGUgeWVwIHllcCB5ZXA")) // swiftlint:disable:this line_length
            }
        }

        xdescribe("loadImageData") {
            describe("good URLs") {
                var image: Data?

                beforeEach {
                    image = try! Data.loadImageData(URL(string: "https://pics.me.me/pudu-blep-22233754.png")!).toBlocking().first()!
                }

                it("loads image data from the internet") {
                    expect(image).notTo(beNil())
                }
            }

            describe("bad URLs") {
                var result: MaterializedSequenceResult<Data?>?

                beforeEach {
                    result = Data.loadImageData(URL(string: "https://www.my.bad.url")!).toBlocking().materialize()
                }

                it("passes along the error") {
                    switch result! {
                    case .failed(_, let error):
                        expect(error).to(beAnInstanceOf(NSError.self))
                    default:
                        fail("expected error")
                    }
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Quick
import Nimble

@testable import Lockbox

class UIButtonSpec: QuickSpec {
    var subject: UIButton!

    override func spec() {
        beforeEach {
            self.subject = UIButton(title: "title", imageName: "back")
        }

        describe("UIButton") {
            describe("button with title and image convenience init") {
                it("correctly sets title color for normal state") {
                    let normalColor = self.subject.titleColor(for: .normal)
                    let expectedColor = Constant.color.buttonTitleColorNormalState
                    expect(normalColor).to(equal(expectedColor))
                }

                it("correctly sets title color for selected state") {
                    let selectedColor = self.subject.titleColor(for: .selected)
                    let expectedColor = Constant.color.buttonTitleColorOtherState
                    expect(selectedColor).to(equal(expectedColor))
                }

                it("correctly sets title color for highlighted state") {
                    let highlightedColor = self.subject.titleColor(for: .highlighted)
                    let expectedColor = Constant.color.buttonTitleColorOtherState
                    expect(highlightedColor).to(equal(expectedColor))
                }

                it("correctly sets title color for disabled state") {
                    let disabledColor = self.subject.titleColor(for: .disabled)
                    let expectedColor = Constant.color.buttonTitleColorOtherState
                    expect(disabledColor).to(equal(expectedColor))
                }

                it("is able to set a normal image using the 'back' image") {
                    let normalImage = self.subject.image(for: .normal)
                    expect(normalImage).toNot(beNil())
                }

                it("is able to set a selected image using the 'back' image") {
                    let selectedImage = self.subject.image(for: .selected)
                    expect(selectedImage).toNot(beNil())
                }

                it("is able to set a highlighted image using the 'back' image") {
                    let highlightedImage = self.subject.image(for: .highlighted)
                    expect(highlightedImage).toNot(beNil())
                }

                it("is able to set a disabled image using the 'back' image") {
                    let disabledImage = self.subject.image(for: .disabled)
                    expect(disabledImage).toNot(beNil())
                }
            }
        }
    }
}

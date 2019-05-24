/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxCocoa
import RxTest

@testable import Lockbox

class ItemDetailCellConfigurationSpec: QuickSpec {
    override func spec() {
        describe("ItemDetailViewCellConfiguration") {
            describe("IdentifiableType") {
                let title = "meow"
                let cellConfig = ItemDetailCellConfiguration(title: title, value: Driver.just("cats"), accessibilityLabel: "something accessible", accessibilityId: "", textFieldEnabled: Driver.just(false))

                it("uses the title as the identity string") {
                    expect(cellConfig.identity).to(equal(title))
                }
            }

            describe("equality") {
                it("uses the title to determine equality") {
                    expect(ItemDetailCellConfiguration(
                            title: "meow",
                            value: Driver.just("cats"),
                            accessibilityLabel: "something accessible",
                            accessibilityId: "",
                            textFieldEnabled: Driver.just(false))
                    ).to(equal(ItemDetailCellConfiguration(
                            title: "meow",
                            value: Driver.just("cats"),
                            accessibilityLabel: "something accessible",
                            accessibilityId: "",
                            textFieldEnabled: Driver.just(false))
                    ))

                    expect(ItemDetailCellConfiguration(
                            title: "woof",
                            value: Driver.just("cats"),
                            accessibilityLabel: "something accessible",
                            accessibilityId: "",
                            textFieldEnabled: Driver.just(false))
                    ).notTo(equal(ItemDetailCellConfiguration(
                            title: "meow",
                            value: Driver.just("cats"),
                            accessibilityLabel: "something accessible",
                            accessibilityId: "",
                            textFieldEnabled: Driver.just(false))
                    ))

                    expect(ItemDetailCellConfiguration(
                            title: "meow",
                            value: Driver.just("dogs"),
                            accessibilityLabel: "something accessible",
                            accessibilityId: "",
                            textFieldEnabled: Driver.just(false))
                    ).to(equal(ItemDetailCellConfiguration(
                            title: "meow",
                            value: Driver.just("cats"),
                            accessibilityLabel: "something accessible",
                            accessibilityId: "",
                            textFieldEnabled: Driver.just(false))
                    ))
                }
            }
        }
    }
}
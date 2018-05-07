/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble

@testable import Lockbox

class ItemSpec: QuickSpec {
    override func spec() {
        var lhs: Item?
        var rhs: Item?

        describe("builder") {
            it("builds the item with all provided parameters") {
                let id = "fdgsfdsfds"
                let disabled = false
                let title = "titlevalue"
                let origins = ["meow", "woof"]
                let tags = ["cats", "dogs"]
                let created = "fsddsffdsfsd"
                let modified = "fsddsffdsfsd"
                let lastUsed = "fsddsffdsfsd"
                let entry = ItemEntry.Builder().kind("fdssdflksdf").build()

                let item = Item.Builder()
                        .id(id)
                        .disabled(disabled)
                        .title(title)
                        .origins(origins)
                        .tags(tags)
                        .created(created)
                        .modified(modified)
                        .lastUsed(lastUsed)
                        .entry(entry)
                        .build()

                expect(item.id).to(equal(id))
                expect(item.disabled).to(equal(disabled))
                expect(item.title).to(equal(title))
                expect(item.origins).to(equal(origins))
                expect(item.tags).to(equal(tags))
                expect(item.created).to(equal(created))
                expect(item.modified).to(equal(modified))
                expect(item.lastUsed).to(equal(lastUsed))
                expect(item.entry).to(equal(entry))
            }
        }

        describe("usedDates") {
            it("computes the date from the given string") {
                let item = Item.Builder()
                        .created("1970-01-01T00:03:20.4500Z")
                        .modified("1970-01-01T00:05:20.4500Z")
                        .lastUsed("1970-01-01T00:05:20.4500Z")
                        .build()

                expect(item.createdDate).to(equal(Date.init(timeIntervalSince1970: 200)))
                expect(item.modifiedDate).to(equal(Date.init(timeIntervalSince1970: 320)))
                expect(item.lastUsedDate).to(equal(Date.init(timeIntervalSince1970: 320)))
            }

            it("returns nil when there is a no date") {
                let item = Item.Builder().build()

                expect(item.createdDate).to(beNil())
                expect(item.modifiedDate).to(beNil())
                expect(item.lastUsedDate).to(beNil())
            }
        }

        describe("equality") {
            it("returns false when the ids are different", closure: {
                lhs = Item.Builder()
                        .entry(ItemEntry.Builder().kind("blah").build())
                        .id("murp")
                        .origins([])
                        .build()
                rhs = Item.Builder()
                        .entry(ItemEntry.Builder().kind("yuck").build())
                        .id("snark")
                        .origins([])
                        .build()

                expect(lhs == rhs).to(beFalse())
            })

            it("returns true when the ids are the same but the entry or origin parameters are different") {
                let id = "murp"
                lhs = Item.Builder()
                        .entry(ItemEntry.Builder().kind("blah").build())
                        .id(id)
                        .origins([])
                        .build()
                rhs = Item.Builder()
                        .entry(ItemEntry.Builder().kind("farts").build())
                        .id(id)
                        .origins([])
                        .build()

                expect(lhs == rhs).to(beFalse())

                lhs = Item.Builder()
                        .entry(ItemEntry.Builder().kind("blah").build())
                        .id(id)
                        .origins([])
                        .build()
                rhs = Item.Builder()
                        .entry(ItemEntry.Builder().kind("blah").build())
                        .id(id)
                        .origins(["www.meow.com"])
                        .build()

                expect(lhs == rhs).to(beFalse())
            }

            it("returns true when the ids are the same and all other parameters are the same") {
                let id = "murp"
                let type = "fart"
                lhs = Item.Builder()
                        .entry(ItemEntry.Builder().kind(type).build())
                        .id(id)
                        .origins([])
                        .build()
                rhs = Item.Builder()
                        .entry(ItemEntry.Builder().kind(type).build())
                        .id(id)
                        .origins([])
                        .build()

                expect(lhs == rhs).to(beTrue())
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble

@testable import Lockbox

class ItemEntrySpec: QuickSpec {
    override func spec() {
        describe("equality") {
            var lhs: ItemEntry?
            var rhs: ItemEntry?

            it("when the type is the same but the username and password are different, the entries are not equal") {
                let type = "butt"
                lhs = ItemEntry.Builder()
                        .kind(type)
                        .username("jlkfd")
                        .password("marple")
                        .notes("something")
                        .build()
                rhs = ItemEntry.Builder()
                        .kind(type)
                        .username("waugh")
                        .password("very secure")
                        .notes("something")
                        .build()

                expect(lhs == rhs).to(beFalse())
            }

            it("when the type and username are the same but the password is different, the entries are not equal") {
                let type = "butt"
                let username = "ellen ripley"
                lhs = ItemEntry.Builder()
                        .kind(type)
                        .username(username)
                        .password("marple")
                        .build()
                rhs = ItemEntry.Builder()
                        .kind(type)
                        .username(username)
                        .password("very secure")
                        .build()

                expect(lhs == rhs).to(beFalse())
            }

            it("when the type and password are the same but the username is different, the entries are not equal") {
                let type = "butt"
                let password = "fart"
                lhs = ItemEntry.Builder()
                        .kind(type)
                        .username("username")
                        .password(password)
                        .build()
                rhs = ItemEntry.Builder()
                        .kind(type)
                        .username("dogs")
                        .password(password)
                        .build()

                expect(lhs == rhs).to(beFalse())
            }

            it("when the username and password are the same but the type is different, the entries are not equal") {
                let username = "ellen ripley"
                let password = "fart"
                lhs = ItemEntry.Builder()
                        .kind("bbbbbbb")
                        .username(username)
                        .password(password)
                        .build()
                rhs = ItemEntry.Builder()
                        .kind("ccccccc")
                        .username(username)
                        .password(password)
                        .build()

                expect(lhs == rhs).to(beFalse())
            }

            it("when the username, password, and type are the same, the entries are equal") {
                let type = "login"
                let username = "ellen ripley"
                let password = "fart"
                lhs = ItemEntry.Builder()
                        .kind(type)
                        .username(username)
                        .password(password)
                        .build()
                rhs = ItemEntry.Builder()
                        .kind(type)
                        .username(username)
                        .password(password)
                        .build()

                expect(lhs == rhs).to(beTrue())
            }
        }
    }
}

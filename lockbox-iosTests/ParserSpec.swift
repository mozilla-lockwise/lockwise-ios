/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble

@testable import Lockbox

class ParserSpec: QuickSpec {
    enum FakeEncoderError: Error {
        case FoundAProblem
    }

    class FakeEncoder: JSONEncoder {
        var shouldThrow = false

        override func encode<T>(_ value: T) throws -> Data where T: Encodable {
            if shouldThrow {
                throw FakeEncoderError.FoundAProblem
            }

            return try super.encode(value)
        }
    }

    var subject: Parser!
    var encoder: FakeEncoder!

    override func spec() {
        beforeEach {
            self.encoder = FakeEncoder()
            self.subject = Parser(encoder: self.encoder)
        }

        describe(".itemFromDictionary()") {
            it("throws invaliddictionary when provided an empty dictionary") {
                expect {
                    try self.subject.itemFromDictionary([:])
                }.to(throwError(ParserError.InvalidDictionary))
            }

            it("throws invaliddictionary when provided a dictionary with only unexpected parameters") {
                expect {
                    try self.subject.itemFromDictionary(["bogus": "foo", "bar": false])
                }.to(throwError(ParserError.InvalidDictionary))
            }

            it("throws invaliddictionary when provided a dictionary without all required parameters") {
                let type = "cat"
                let title = "butt"
                let username = "me"
                expect {
                    try self.subject.itemFromDictionary(
                            [
                                "entry": [
                                    "type": type,
                                    "username": username
                                ],
                                "title": title
                            ])
                }.to(throwError(ParserError.InvalidDictionary))
            }

            it("populates item correctly when provided a dictionary with some unexpected parameters") {
                let kind = "cat"
                let id = "fdkjsfdhkjfds"
                let origins = ["www.maps.com"]
                let item = try! self.subject.itemFromDictionary(
                        ["bogus": "foo",
                         "bar": false,
                         "id": id,
                         "origins": origins,
                         "entry": [
                             "kind": kind,
                             "farts": "mcgee"
                         ]
                        ])
                let expectedEntry = ItemEntry.Builder()
                        .kind(kind)
                        .build()
                let expectedItem = Item.Builder()
                        .id(id)
                        .origins(origins)
                        .entry(expectedEntry)
                        .build()

                expect(item).to(equal(expectedItem))
                expect(item.entry).to(equal(expectedEntry))
            }

            it("populates item correctly when provided a dictionary with expected parameters") {
                let kind = "cat"
                let id = "fdkjsfdhkjfds"
                let origins = ["www.maps.com"]
                let title = "butt"
                let username = "me"
                let item = try! self.subject.itemFromDictionary(
                        [
                            "id": id,
                            "origins": origins,
                            "entry": [
                                "kind": kind,
                                "username": username
                            ],
                            "title": title
                        ])

                let expectedEntry = ItemEntry.Builder()
                        .kind(kind)
                        .username(username)
                        .build()
                let expectedItem = Item.Builder()
                        .id(id)
                        .origins(origins)
                        .entry(expectedEntry)
                        .title(title)
                        .build()

                expect(item).to(equal(expectedItem))
            }
        }

        describe("jsonStringFromItem()") {
            describe("when json encoding fails") {
                beforeEach {
                    self.encoder.shouldThrow = true
                }

                it("throws the InvalidItem error") {
                    let item = Item.Builder()
                            .id("dfgljkfsdlead")
                            .entry(ItemEntry.Builder().kind("login").build())
                            .origins(["www.neopets.com"])
                            .build()

                    expect {
                        try self.subject.jsonStringFromItem(item)
                    }.to(throwError(ParserError.InvalidItem))
                }
            }

            describe("when json encoding succeeds") {
                beforeEach {
                    self.encoder.shouldThrow = false
                }

                it("forms a valid json string") {
                    let item = Item.Builder()
                            .id("dfgljkfsdlead")
                            .entry(ItemEntry.Builder().kind("login").build())
                            .origins(["www.neopets.com"])
                            .build()

                    let json = try! self.subject.jsonStringFromItem(item)
                    expect(json).to(equal("{\"id\":\"dfgljkfsdlead\",\"origins\":[\"www.neopets.com\"],\"entry\":{\"kind\":\"login\"}}")) // swiftlint:disable:this line_length
                }

            }
        }
    }
}

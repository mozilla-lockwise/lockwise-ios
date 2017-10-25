import Quick
import Nimble

@testable import lockbox_ios

class ParserSpec : QuickSpec {
    override func spec() {
        describe(".itemFromDictionary()") {
            it("throws invaliddictionary when provided an empty dictionary") {
                expect(try Parser.itemFromDictionary([:])).to(throwError(ParserError.InvalidDictionary))
            }
            
            it("throws invaliddictionary when provided a dictionary with only unexpected parameters") {
                expect(try Parser.itemFromDictionary(["bogus":"foo", "bar": false])).to(throwError())
            }
            
            it("returns ItemNotFound when provided a dictionary without all required parameters") {
                let type = "cat"
                let origins = ["www.maps.com"]
                let title = "butt"
                let username = "me"
                expect( try Parser.itemFromDictionary(
                    [
                        "origins":origins,
                        "entry":[
                            "type":type,
                            "username":username
                        ],
                        "title":title
                    ])).to(throwError())
            }
            
            it("populates item correctly when provided a dictionary with some unexpected parameters") {
                let type = "cat"
                let id = "fdkjsfdhkjfds"
                let origins = ["www.maps.com"]
                let item = try! Parser.itemFromDictionary(
                    ["bogus":"foo",
                     "bar": false,
                     "id":id,
                     "origins":origins,
                     "entry":[
                        "type":type,
                        "farts":"mcgee"
                        ]
                    ])
                let expectedEntry = ItemEntry.Builder()
                    .type(type)
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
                let type = "cat"
                let id = "fdkjsfdhkjfds"
                let origins = ["www.maps.com"]
                let title = "butt"
                let username = "me"
                let item = try! Parser.itemFromDictionary(
                    [
                        "id":id,
                        "origins":origins,
                        "entry":[
                            "type":type,
                            "username":username
                        ],
                        "title":title
                    ])
                
                let expectedEntry = ItemEntry.Builder()
                    .type(type)
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
            it("forms a valid json string") {
                let item = Item.Builder()
                    .id("dfgljkfsdlead")
                    .entry(ItemEntry.Builder().type("login").build())
                    .origins(["www.neopets.com"])
                    .build()
                
                let json = try! Parser.jsonStringFromItem(item)
                expect(json).to(equal("{\"id\":\"dfgljkfsdlead\",\"origins\":[\"www.neopets.com\"],\"entry\":{\"type\":\"login\"}}"))
            }
        }
    }
}

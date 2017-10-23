import Quick
import Nimble

@testable import lockbox_ios

class ParserSpec : QuickSpec {
    override func spec() {
        let itemNotFound = Item.ItemNotFound()
        
        describe(".itemFromDictionary()") {
            it("returns ItemNotFound when provided an empty dictionary") {
                let item = Parser.itemFromDictionary([:])
                
                expect(item).to(equal(itemNotFound))
            }
            
            it("returns ItemNotFound when provided a dictionary with only unexpected parameters") {
                let item = Parser.itemFromDictionary(["bogus":"foo", "bar": false])
                
                expect(item).to(equal(itemNotFound))
            }
            
            it("returns ItemNotFound when provided a dictionary without all required parameters") {
                let type = "cat"
                let origins = ["www.maps.com"]
                let title = "butt"
                let username = "me"
                let item = Parser.itemFromDictionary(
                    [
                        "origins":origins,
                        "entry":[
                            "type":type,
                            "username":username
                        ],
                        "title":title
                    ])
                
                expect(item).to(equal(itemNotFound))
            }
            
            it("populates item correctly when provided a dictionary with some unexpected parameters") {
                let type = "cat"
                let id = "fdkjsfdhkjfds"
                let origins = ["www.maps.com"]
                let item = Parser.itemFromDictionary(
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
                let item = Parser.itemFromDictionary(
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
                
                let json = Parser.jsonStringFromItem(item)
                expect(json).to(equal("{\"id\":\"dfgljkfsdlead\",\"origins\":[\"www.neopets.com\"],\"entry\":{\"type\":\"login\"}}"))
            }
        }
    }
}

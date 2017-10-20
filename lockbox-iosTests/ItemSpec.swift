import Quick
import Nimble

@testable import lockbox_ios

class ItemSpec : QuickSpec {
    override func spec() {
        var lhs:Item?
        var rhs:Item?
        
        describe("equality") {
            it("returns false when the ids are different", closure: {
                lhs = Item.Builder()
                    .entry(ItemEntry.Builder().type("blah").build())
                    .id("murp")
                    .origins([])
                    .build()
                rhs = Item.Builder()
                    .entry(ItemEntry.Builder().type("yuck").build())
                    .id("snark")
                    .origins([])
                    .build()
                
                expect(lhs == rhs).to(beFalse())
            })
            
            it("returns true when the ids are the same but other parameters are different") {
                let id = "murp"
                lhs = Item.Builder()
                    .entry(ItemEntry.Builder().type("blah").build())
                    .id(id)
                    .origins([])
                    .build()
                rhs = Item.Builder()
                    .entry(ItemEntry.Builder().type("farts").build())
                    .id(id)
                    .origins([])
                    .build()
                
                expect(lhs == rhs).to(beTrue())
            }
            
            it("returns true when the ids are the same and all other parameters are the same") {
                let id = "murp"
                let type = "fart"
                lhs = Item.Builder()
                    .entry(ItemEntry.Builder().type(type).build())
                    .id(id)
                    .origins([])
                    .build()
                rhs = Item.Builder()
                    .entry(ItemEntry.Builder().type(type).build())
                    .id(id)
                    .origins([])
                    .build()
                
                expect(lhs == rhs).to(beTrue())
            }
        }
    }
}

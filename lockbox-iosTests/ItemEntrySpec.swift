import Quick
import Nimble

@testable import lockbox_ios

class ItemEntrySpec : QuickSpec {
    override func spec() {
        describe("equality") {
            var lhs:ItemEntry?
            var rhs:ItemEntry?
            
            it("when the type is the same but the username and password are different, the entries are not equal") {
                let type = "butt"
                lhs = ItemEntry.Builder()
                    .type(type)
                    .username("jlkfd")
                    .password("marple")
                    .build()
                rhs = ItemEntry.Builder()
                    .type(type)
                    .username("waugh")
                    .password("very secure")
                    .build()
                
                expect(lhs == rhs).to(beFalse())
            }
            
            it("when the type and username are the same but the password is different, the entries are not equal") {
                let type = "butt"
                let username = "ellen ripley"
                lhs = ItemEntry.Builder()
                    .type(type)
                    .username(username)
                    .password("marple")
                    .build()
                rhs = ItemEntry.Builder()
                    .type(type)
                    .username(username)
                    .password("very secure")
                    .build()
                
                expect(lhs == rhs).to(beFalse())
            }
            
            it("when the type and password are the same but the username is different, the entries are not equal") {
                let type = "butt"
                let password = "fart"
                lhs = ItemEntry.Builder()
                    .type(type)
                    .username("username")
                    .password(password)
                    .build()
                rhs = ItemEntry.Builder()
                    .type(type)
                    .username("dogs")
                    .password(password)
                    .build()
                
                expect(lhs == rhs).to(beFalse())
            }
            
            it("when the username and password are the same but the type is different, the entries are not equal") {
                let username = "ellen ripley"
                let password = "fart"
                lhs = ItemEntry.Builder()
                    .type("bbbbbbb")
                    .username(username)
                    .password(password)
                    .build()
                rhs = ItemEntry.Builder()
                    .type("ccccccc")
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
                    .type(type)
                    .username(username)
                    .password(password)
                    .build()
                rhs = ItemEntry.Builder()
                    .type(type)
                    .username(username)
                    .password(password)
                    .build()
                
                expect(lhs == rhs).to(beTrue())
            }
        }
    }
}

import Foundation

struct ItemHistory : Codable {
    var create:String
}

struct ItemEntry : Codable {
    var type:String
    var username:String?
    var password:String?
    
    init(type:String) {
        self.type = type
    }
}

struct Item : Codable {
    var id:String
    var disabled:Bool?
    var title:String?
    var origins:[String]
    var tags:[String]?
    var created:String?
    var modified:String?
    var lastUsed:String?
    var entry:ItemEntry
    var history:[ItemHistory]?
    
    init(id:String, origins:[String], entry:ItemEntry) {
        self.id = id
        self.origins = origins
        self.entry = entry
    }
    
    class Builder {
        private var item:Item!
        
        init(type:String, id:String, origins:[String]) {
            let entry = ItemEntry(type:type)
            self.item = Item(id:id, origins:origins, entry:entry)
        }
        
        func build() -> Item {
            return self.item
        }
        
        func disabled(_ disabled:Bool) -> Builder {
            self.item.disabled = disabled
            return self
        }
        
        func title(_ title:String) -> Builder {
            self.item.title = title
            return self
        }
        
        func username(_ username:String) -> Builder {
            self.item.entry.username = username
            return self
        }
        
        func password(_ password:String) -> Builder {
            self.item.entry.password = password
            return self
        }
        
        func tags(_ tags:[String]) -> Builder {
            self.item.tags = tags
            return self
        }
        
        func created(_ created:String) -> Builder {
            self.item.created = created
            return self
        }
        
        func modified(_ modified:String) -> Builder {
            self.item.modified = modified
            return self
        }
        
        func lastUsed(_ lastUsed:String) -> Builder {
            self.item.lastUsed = lastUsed
            return self
        }
    }
}

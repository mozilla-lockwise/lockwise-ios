/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class Item: Codable, Equatable {
    var id: String?
    var disabled: Bool?
    var title: String?
    var origins: [String]
    var tags: [String]?
    var created: String?
    var modified: String?
    var lastUsed: String?
    var entry: ItemEntry

    var createdDate: Date? {
        return Date(iso8601DateString: self.created ?? "")
    }

    var modifiedDate: Date? {
        return Date(iso8601DateString: self.modified ?? "")
    }

    var lastUsedDate: Date? {
        return Date(iso8601DateString: self.lastUsed ?? "")
    }

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case disabled = "disabled"
        case title = "title"
        case origins = "origins"
        case tags = "tags"
        case created = "created"
        case modified = "modified"
        case lastUsed = "last_used"
        case entry = "entry"

        static let allValues = [id, disabled, title, origins, tags, created, modified, lastUsed, entry]
    }

    init(origins: [String], entry: ItemEntry) {
        self.origins = origins
        self.entry = entry
    }

    static func ==(lhs: Item, rhs: Item) -> Bool {
        return lhs.id == rhs.id &&
                lhs.entry == rhs.entry &&
                lhs.origins.elementsEqual(rhs.origins) &&
                lhs.modified == rhs.modified &&
                lhs.lastUsed == rhs.lastUsed

    }

    class Builder {
        private var item: Item!

        init() {
            let entry = ItemEntry(type: "")
            self.item = Item(origins: [], entry: entry)
        }

        func build() -> Item {
            return self.item
        }

        func id(_ id: String) -> Builder {
            self.item.id = id
            return self
        }

        func origins(_ origins: [String]) -> Builder {
            self.item.origins = origins
            return self
        }

        func entry(_ entry: ItemEntry) -> Builder {
            self.item.entry = entry
            return self
        }

        func disabled(_ disabled: Bool) -> Builder {
            self.item.disabled = disabled
            return self
        }

        func title(_ title: String) -> Builder {
            self.item.title = title
            return self
        }

        func tags(_ tags: [String]) -> Builder {
            self.item.tags = tags
            return self
        }

        func created(_ created: String) -> Builder {
            self.item.created = created
            return self
        }

        func modified(_ modified: String) -> Builder {
            self.item.modified = modified
            return self
        }

        func lastUsed(_ lastUsed: String) -> Builder {
            self.item.lastUsed = lastUsed
            return self
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

struct ItemEntry: Codable, Equatable {
    var kind: String
    var username: String?
    var password: String?
    var notes: String?

    init(type: String) {
        self.kind = type
    }

    static func ==(lhs: ItemEntry, rhs: ItemEntry) -> Bool {
        return lhs.kind == rhs.kind &&
                lhs.password == rhs.password &&
                lhs.username == rhs.username
    }

    class Builder {
        private var itemEntry: ItemEntry!

        init() {
            self.itemEntry = ItemEntry(type: "")
        }

        func build() -> ItemEntry {
            return self.itemEntry
        }

        func kind(_ kind: String) -> Builder {
            self.itemEntry.kind = kind
            return self
        }

        func username(_ username: String) -> Builder {
            self.itemEntry.username = username
            return self
        }

        func password(_ password: String) -> Builder {
            self.itemEntry.password = password
            return self
        }

        func notes(_ notes: String) -> Builder {
            self.itemEntry.notes = notes
            return self
        }
    }
}

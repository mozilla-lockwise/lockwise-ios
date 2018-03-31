/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension Date {
    public init?(iso8601DateString: String) {
        let trimmedIsoString = iso8601DateString.replacingOccurrences(
                of: "\\.\\d+",
                with: "",
                options: .regularExpression
        )
        if let date = ISO8601DateFormatter().date(from: trimmedIsoString) {
            self = date
        } else {
            return nil
        }
    }
}

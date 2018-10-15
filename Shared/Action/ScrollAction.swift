/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/*
 * ScrollAction is an enum in case there are further automated scroll actions that
 * are needed in future.
 */
enum ScrollAction: Action {
    case toTop
}

extension ScrollAction: Equatable {
    static func ==(lhs: ScrollAction, rhs: ScrollAction) -> Bool {
        switch(lhs, rhs) {
        case (.toTop, .toTop):
            return true
        }
    }
}

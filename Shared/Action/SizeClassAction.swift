/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

enum SizeClassAction: Action {
    case changed(traitCollection: UITraitCollection)
}

extension SizeClassAction: Equatable {
    static func ==(lhs: SizeClassAction, rhs: SizeClassAction) -> Bool {
        switch (lhs, rhs) {
        case (.changed(let lhTraits), .changed(let rhTraits)):
            return lhTraits == rhTraits
        }
    }
}

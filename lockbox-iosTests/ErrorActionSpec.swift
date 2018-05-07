/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

public func matchErrorAction(_ expected: ErrorAction) -> Predicate<ErrorAction> {
    return Predicate.fromDeprecatedClosure { actualExpression, _ in
        let actualErrorType: ErrorAction? = try actualExpression.evaluate()

        var matches = false
        if let actualErrorType = actualErrorType,
           actualErrorType.error._domain == expected.error._domain,
           actualErrorType.error._code == expected.error._code {
            matches = true
        }
        return matches
    }.requireNonNil
}

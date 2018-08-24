/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift

extension ObservableType {
    public func filterByType<T>(class: T.Type) -> Observable<T> {
        return self.filter {
            $0 is T
        }.map {
            $0 as! T // swiftlint:disable:this force_cast
        }
    }
}

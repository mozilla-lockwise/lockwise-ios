/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import Quick
import Nimble

@testable import Lockbox

class ObservableSpec: QuickSpec {
    class Common {}
    class A: Common {}
    class B: Common {}

    var subject: Observable<Common>!

    override func spec() {
        describe("filtering by type") {
            beforeEach {
                self.subject = Observable.from([A(), B(), B(), A()])
            }

            it("changes the type of the observable") {
                expect(self.subject.filterByType(class: A.self)).to(beAKindOf(Observable<A>.self))
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
// swiftlint:disable line_length
// swiftlint:disable force_cast

import Quick
import Nimble
import WebKit
import RxTest
import RxSwift
import FxAClient

@testable import Lockbox

class DataStoreActionSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        var actionArgument: Action?

        override func dispatch(action: Action) {
            self.actionArgument = action
        }
    }

    var dispatcher: FakeDispatcher!
    private let dataStoreName: String = "dstore"
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()

    override func spec() {
        describe("Action equality") {
            it("initialize is always equal") {
                // tricky to test because we cannot construct FxAClient.OAuthInfo
            }

            it("non-associated data enum values are always equal") {
                expect(DataStoreAction.lock).to(equal(DataStoreAction.lock))
                expect(DataStoreAction.unlock).to(equal(DataStoreAction.unlock))
                expect(DataStoreAction.reset).to(equal(DataStoreAction.reset))
                expect(DataStoreAction.sync).to(equal(DataStoreAction.sync))
            }

            it("touch is equal based on IDs") {
                expect(DataStoreAction.touch(id: "meow")).to(equal(DataStoreAction.touch(id: "meow")))
                expect(DataStoreAction.touch(id: "meow")).notTo(equal(DataStoreAction.touch(id: "woof")))
            }

            it("different enum types are never equal") {
                expect(DataStoreAction.unlock).notTo(equal(DataStoreAction.lock))
                expect(DataStoreAction.lock).notTo(equal(DataStoreAction.unlock))
                expect(DataStoreAction.sync).notTo(equal(DataStoreAction.reset))
                expect(DataStoreAction.reset).notTo(equal(DataStoreAction.sync))
            }
        }
    }
}

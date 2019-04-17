/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift
import Reachability

@testable import Lockbox

class NetworkStoreSpec: QuickSpec {
    class FakeReachability: ReachabilityProtocol {
        var startCalled = false

        var whenReachable: Reachability.NetworkReachable?

        var whenUnreachable: Reachability.NetworkUnreachable?

        func startNotifier() throws {
            startCalled = true
        }
    }

    var dispatcher: Dispatcher!
    var reachability: FakeReachability!
    var subject: NetworkStore!

    override func spec() {
        describe("NetworkStore") {
            beforeEach {
                self.dispatcher = Dispatcher()
                self.reachability = FakeReachability()
                self.subject = NetworkStore(reachability: self.reachability)
            }

            describe("reachable call") {
                beforeEach {
                    self.reachability.whenReachable!(Reachability()!)
                }

                it("updates the connectedtonetwork status") {
                    expect(self.subject.isConnectedToNetwork).to(beTrue())
                }
            }

            describe("unreachable call") {
                beforeEach {
                    self.reachability.whenUnreachable!(Reachability()!)
                }

                it("updates the connectedtonetwork status") {
                    expect(self.subject.isConnectedToNetwork).to(beFalse())
                }
            }
        }
    }
}

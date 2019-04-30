/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

class ApplicationLifecycleActionSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        var actionTypeArgument: Action?

        override func dispatch(action: Action) {
            self.actionTypeArgument = action
        }
    }

    private var dispatcher: FakeDispatcher!

    override func spec() {
        describe("LifecycleAction") {
            describe("telemetry") {
                it("always returns the app event object") {
                    expect(LifecycleAction.foreground.eventObject).to(equal(TelemetryEventObject.app))
                    expect(LifecycleAction.background.eventObject).to(equal(TelemetryEventObject.app))
                    expect(LifecycleAction.startup.eventObject).to(equal(TelemetryEventObject.app))
                }

                it("returns different methods based on the action") {
                    expect(LifecycleAction.foreground.eventMethod).to(equal(TelemetryEventMethod.foreground))
                    expect(LifecycleAction.background.eventMethod).to(equal(TelemetryEventMethod.background))
                    expect(LifecycleAction.startup.eventMethod).to(equal(TelemetryEventMethod.startup))
                }

                it("returns no value or extras") {
                    expect(LifecycleAction.foreground.value).to(beNil())
                    expect(LifecycleAction.background.value).to(beNil())
                    expect(LifecycleAction.startup.value).to(beNil())
                    expect(LifecycleAction.foreground.extras).to(beNil())
                    expect(LifecycleAction.background.extras).to(beNil())
                    expect(LifecycleAction.startup.extras).to(beNil())
                }
            }

            describe("equality") {
                it("basic lifecycles") {
                    expect(LifecycleAction.foreground).to(equal(LifecycleAction.foreground))
                    expect(LifecycleAction.background).to(equal(LifecycleAction.background))
                    expect(LifecycleAction.startup).to(equal(LifecycleAction.startup))
                    expect(LifecycleAction.shutdown).to(equal(LifecycleAction.shutdown))
                    expect(LifecycleAction.foreground).notTo(equal(LifecycleAction.background))
                    expect(LifecycleAction.background).notTo(equal(LifecycleAction.startup))
                    expect(LifecycleAction.startup).notTo(equal(LifecycleAction.shutdown))
                    expect(LifecycleAction.shutdown).notTo(equal(LifecycleAction.foreground))
                }

                it("upgrade") {
                    expect(LifecycleAction.upgrade(from: 1, to: 1)).to(equal(LifecycleAction.upgrade(from: 1, to: 1)))
                    expect(LifecycleAction.upgrade(from: 1, to: 2)).to(equal(LifecycleAction.upgrade(from: 1, to: 2)))
                    expect(LifecycleAction.upgrade(from: 1, to: 2)).notTo(equal(LifecycleAction.upgrade(from: 2, to: 2)))
                    expect(LifecycleAction.upgrade(from: 1, to: 2)).notTo(equal(LifecycleAction.upgrade(from: 2, to: 3)))
                    expect(LifecycleAction.upgrade(from: 2, to: 2)).notTo(equal(LifecycleAction.upgrade(from: 2, to: 3)))
                }
            }
        }
    }
}

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
    var subject: ApplicationLifecycleActionHandler!

    override func spec() {
        describe("ApplicationLifecycleActionHandler") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = ApplicationLifecycleActionHandler(dispatcher: self.dispatcher)
            }

            describe("invoke") {
                beforeEach {
                    self.subject.invoke(LifecycleAction.foreground)
                }

                it("dispatches actions to the dispatcher") {
                    expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                    let argument = self.dispatcher.actionTypeArgument as! LifecycleAction
                    expect(argument).to(equal(LifecycleAction.foreground))
                }
            }
        }

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
        }
    }
}

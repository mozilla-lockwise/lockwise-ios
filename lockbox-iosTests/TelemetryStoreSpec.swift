/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift

@testable import Lockbox

class TelemetryStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    struct FakeTelemetryAction: TelemetryAction {
        var eventMethod: TelemetryEventMethod
        var eventObject: TelemetryEventObject
        var value: String?
        var extras: [String: Any?]?
    }

    private var dispatcher: FakeDispatcher!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: TelemetryStore!

    override func spec() {
        describe("CopyDisplayStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = TelemetryStore(dispatcher: self.dispatcher)
            }

            describe("copyDisplay") {
                var telemetryObserver = self.scheduler.createObserver(TelemetryAction.self)

                beforeEach {
                    telemetryObserver = self.scheduler.createObserver(TelemetryAction.self)

                    self.subject.telemetryFilter
                            .bind(to: telemetryObserver)
                            .disposed(by: self.disposeBag)
                }

                it("passes through TelemetryAction from the dispatcher") {
                    self.dispatcher.fakeRegistration.onNext(FakeTelemetryAction(eventMethod: .tap, eventObject: .entryList, value: nil, extras: nil))

                    expect(telemetryObserver.events.count).to(equal(1))
                    expect(telemetryObserver.events.first!.value.element!.eventMethod).to(equal(TelemetryEventMethod.tap))
                    expect(telemetryObserver.events.first!.value.element!.eventObject).to(equal(TelemetryEventObject.entryList))
                }

                it("does not pass through non-ItemDetailDisplayActions") {
                    self.dispatcher.fakeRegistration.onNext(AccountAction.clear)

                    expect(telemetryObserver.events.count).to(equal(0))
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift

@testable import Lockbox

class LifecycleStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    private var dispatcher: FakeDispatcher!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: LifecycleStore!

    override func spec() {
        describe("LifecycleStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = LifecycleStore(dispatcher: self.dispatcher)
            }

            describe("copyDisplay") {
                var lifecycleObserver = self.scheduler.createObserver(LifecycleAction.self)

                beforeEach {
                    lifecycleObserver = self.scheduler.createObserver(LifecycleAction.self)

                    self.subject.lifecycleEvents
                            .bind(to: lifecycleObserver)
                            .disposed(by: self.disposeBag)
                }

                it("passes through LifecycleActions from the dispatcher") {
                    self.dispatcher.fakeRegistration.onNext(LifecycleAction.foreground)

                    expect(lifecycleObserver.events.count).to(equal(1))
                    expect(lifecycleObserver.events.first!.value.element).to(equal(LifecycleAction.foreground))
                }

                it("does not pass through non-Lifecycle actions") {
                    self.dispatcher.fakeRegistration.onNext(LoginRouteAction.welcome)

                    expect(lifecycleObserver.events.count).to(equal(0))
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class ItemDetailStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    private var dispatcher: FakeDispatcher!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: ItemDetailStore!

    override func spec() {
        describe("ItemDetailStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = ItemDetailStore(dispatcher: self.dispatcher)
            }

            describe("itemDetailDisplay") {
                var displayObserver = self.scheduler.createObserver(ItemDetailDisplayAction.self)

                beforeEach {
                    displayObserver = self.scheduler.createObserver(ItemDetailDisplayAction.self)

                    self.subject.itemDetailDisplay
                            .drive(displayObserver)
                            .disposed(by: self.disposeBag)
                }

                it("passes through ItemDetailDisplayActions from the dispatcher") {
                    self.dispatcher.fakeRegistration.onNext(ItemDetailDisplayAction.togglePassword(displayed: true))

                    expect(displayObserver.events.count).to(equal(1))
                    expect(displayObserver.events.first!.value.element!).to(equal(.togglePassword(displayed: true)))
                }

                it("does not pass through non-ItemDetailDisplayActions") {
                    self.dispatcher.fakeRegistration.onNext(LoginRouteAction.welcome)

                    expect(displayObserver.events.count).to(equal(0))
                }
            }

        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class ItemListDisplayStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    private var scheduler: TestScheduler = TestScheduler(initialClock: 1)
    private var disposeBag = DisposeBag()

    private var dispatcher: FakeDispatcher!
    var subject: ItemListDisplayStore!

    override func spec() {
        describe("ItemListDisplayStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = ItemListDisplayStore(dispatcher: self.dispatcher)
            }

            describe("onRoute") {
                var displayObserver = self.scheduler.createObserver(ItemListDisplayAction.self)

                beforeEach {
                    displayObserver = self.scheduler.createObserver(ItemListDisplayAction.self)

                    self.subject.listDisplay
                            .subscribe(displayObserver)
                            .disposed(by: self.disposeBag)

                    self.dispatcher.fakeRegistration.onNext(ItemListSortingAction.alphabetically)
                }

                it("pushes dispatched route actions to observers") {
                    expect(displayObserver.events.last).notTo(beNil())
                    let element = displayObserver.events.last!.value.element as! ItemListSortingAction
                    expect(element).to(equal(ItemListSortingAction.alphabetically))
                }

                it("pushes new actions to observers") {
                    self.dispatcher.fakeRegistration.onNext(ItemListFilterAction(filteringText: "blah"))
                    expect(displayObserver.events.count).to(equal(2))
                }

                it("does not push non-ItemListDisplay events") {
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.locked(locked: false))
                    expect(displayObserver.events.count).to(equal(1))
                }
            }
        }
    }
}

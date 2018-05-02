/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class FxAStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    private var dispatcher: FakeDispatcher!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: FxAStore!

    override func spec() {
        describe("FxAStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = FxAStore(dispatcher: self.dispatcher)
            }

            describe("fxADisplay") {
                var displayObserver = self.scheduler.createObserver(FxADisplayAction.self)
                beforeEach {
                    displayObserver = self.scheduler.createObserver(FxADisplayAction.self)

                    self.subject.fxADisplay
                            .subscribe(displayObserver)
                            .disposed(by: self.disposeBag)

                    self.dispatcher.fakeRegistration.onNext(FxADisplayAction.fetchingUserInformation)
                }

                it("pushes unique FxADisplay actions to observers") {
                    expect(displayObserver.events.count).to(be(1))
                    expect(displayObserver.events.first!.value.element)
                            .to(equal(FxADisplayAction.fetchingUserInformation))
                }

                it("only pushes unique FxADisplay actions to observers") {
                    self.dispatcher.fakeRegistration.onNext(FxADisplayAction.fetchingUserInformation)
                    expect(displayObserver.events.count).to(be(1))

                    self.dispatcher.fakeRegistration.onNext(FxADisplayAction.finishedFetchingUserInformation)
                    expect(displayObserver.events.count).to(be(2))
                }

                it("does not push non-FxADisplayAction actions") {
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.list(list: [:]))
                    expect(displayObserver.events.count).to(be(1))
                }
            }
        }
    }
}

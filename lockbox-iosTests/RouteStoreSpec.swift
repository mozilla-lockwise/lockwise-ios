/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class RouteStoreSpec : QuickSpec {
    class FakeDispatcher : Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    private var scheduler:TestScheduler = TestScheduler(initialClock: 1)
    private var disposeBag = DisposeBag()

    private var dispatcher:FakeDispatcher!
    var subject:RouteStore!

    override func spec() {
        describe("RouteStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = RouteStore(dispatcher: self.dispatcher)
            }

            describe("onRoute") {
                var routeObserver = self.scheduler.createObserver(RouteAction.self)

                beforeEach {
                    routeObserver = self.scheduler.createObserver(RouteAction.self)

                    self.subject.onRoute
                            .subscribe(routeObserver)
                            .disposed(by: self.disposeBag)

                    self.dispatcher.fakeRegistration.onNext(LoginRouteAction.fxa)
                }

                it("pushes dispatched route actions to observers") {
                    expect(routeObserver.events.last).notTo(beNil())
                    let element = routeObserver.events.last!.value.element as! LoginRouteAction
                    expect(element).to(equal(LoginRouteAction.fxa))
                }

                it("does not push the same LoginRoute action twice") {
                    self.dispatcher.fakeRegistration.onNext(LoginRouteAction.fxa)
                    expect(routeObserver.events.count).to(equal(2))
                }

                it("does not push the same MainRoute action twice") {
                    self.dispatcher.fakeRegistration.onNext(MainRouteAction.list)
                    self.dispatcher.fakeRegistration.onNext(MainRouteAction.list)
                    expect(routeObserver.events.count).to(equal(3))
                }

                it("pushes new actions to observers") {
                    self.dispatcher.fakeRegistration.onNext(MainRouteAction.list)
                    expect(routeObserver.events.count).to(equal(3))
                }

                it("does not push non-RouteAction events") {
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.locked(locked: false))
                    expect(routeObserver.events.count).to(equal(2))
                }
            }
        }
    }
}

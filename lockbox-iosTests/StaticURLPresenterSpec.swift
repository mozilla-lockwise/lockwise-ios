/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import WebKit
import RxCocoa
import RxSwift
import RxTest

@testable import Lockbox

class StaticURLPresenterSpec: QuickSpec {
    class FakeView: StaticURLViewProtocol {
        var returnRouteStub: RouteAction!
        var networkDisclaimerObserver: TestableObserver<Bool>!
        var closeTappedStub = PublishSubject<Void>()
        var retryButtonStub = PublishSubject<Void>()
        var reloadCalled = false

        var returnRoute: RouteAction {
            return returnRouteStub
        }

        var closeTapped: Observable<Void>? {
            return closeTappedStub.asObservable()
        }

        var retryButtonTapped: Observable<Void> {
            return retryButtonStub.asObservable()
        }

        var networkDisclaimerHidden: AnyObserver<Bool> {
            return networkDisclaimerObserver.asObserver()
        }

        func reload() {
            reloadCalled = true
        }
    }

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    class FakeNetworkStore: NetworkStore {
        let connectedToNetworkStub = PublishSubject<Bool>()

        override var connectedToNetwork: Observable<Bool> {
            return self.connectedToNetworkStub.asObservable()
        }
    }

    private var view: FakeView!
    private var dispatcher: FakeDispatcher!
    private var networkStore: FakeNetworkStore!
    var subject: StaticURLPresenter!
    private var scheduler = TestScheduler(initialClock: 0)

    override func spec() {
        describe("StaticURLPresenterSpec") {
            beforeEach {
                self.view = FakeView()
                self.view.networkDisclaimerObserver = self.scheduler.createObserver(Bool.self)
                self.dispatcher = FakeDispatcher()
                self.networkStore = FakeNetworkStore()
                self.subject = StaticURLPresenter(
                        view: self.view,
                        dispatcher: self.dispatcher,
                        networkStore: self.networkStore
                )
            }

            describe("onViewReady") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("closeTapped") {
                    beforeEach {
                        self.view.returnRouteStub = MainRouteAction.list
                        self.view.closeTappedStub.onNext(())
                    }

                    it("dispatches the return route action") {
                        expect(self.dispatcher.dispatchedActions.last as! MainRouteAction).to(equal(MainRouteAction.list))
                    }
                }

                describe("connected to network") {
                    describe("being connected") {
                        beforeEach {
                            self.networkStore.connectedToNetworkStub.onNext(true)
                        }

                        it("hides the network disclaimer and loads the content") {
                            expect(self.view.networkDisclaimerObserver.events.last?.value.element).to(beTrue())
                            expect(self.view.reloadCalled).to(beTrue())
                        }

                        it("does not reload on future events") {
                            self.view.reloadCalled = false
                            self.networkStore.connectedToNetworkStub.onNext(true)
                            expect(self.view.reloadCalled).to(beFalse())
                        }
                    }

                    describe("being disconnected") {
                        beforeEach {
                            self.networkStore.connectedToNetworkStub.onNext(false)
                        }

                        it("hides the network disclaimer and loads the content") {
                            expect(self.view.networkDisclaimerObserver.events.last?.value.element).to(beFalse())
                            expect(self.view.reloadCalled).to(beFalse())
                        }

                        it("reloads on future connection events") {
                            self.view.reloadCalled = false
                            self.networkStore.connectedToNetworkStub.onNext(true)
                            expect(self.view.reloadCalled).to(beTrue())
                        }
                    }
                }

                describe("retry button") {
                    beforeEach {
                        self.view.retryButtonStub.onNext(())
                    }

                    it("dispatches the retry action") {
                        expect(self.dispatcher.dispatchedActions.last as? NetworkAction).to(equal(NetworkAction.retry))
                    }
                }
            }
        }
    }
}

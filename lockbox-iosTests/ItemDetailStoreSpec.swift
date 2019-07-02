/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest
import SwiftKeychainWrapper
import MozillaAppServices

@testable import Lockbox

class ItemDetailStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    class FakeSizeClassStore: SizeClassStore {
        let shouldDisplaySidebarStub = ReplaySubject<Bool>.create(bufferSize: 1)

        override var shouldDisplaySidebar: Observable<Bool> {
            return self.shouldDisplaySidebarStub.asObservable()
        }
    }

    class FakeLifecycleStore: LifecycleStore {
        let lifecycleEventsStub = PublishSubject<LifecycleAction>()

        override var lifecycleEvents: Observable<LifecycleAction> {
            return self.lifecycleEventsStub.asObservable()
        }
    }

    class FakeRouteStore: RouteStore {
        let routeEventsStub = PublishSubject<RouteAction>()

        override var onRoute: Observable<RouteAction> {
            return self.routeEventsStub.asObservable()
        }
    }

    class FakeDataStore: DataStore {
        let syncStateStub = ReplaySubject<SyncState>.create(bufferSize: 1)

        init(dispatcher: Dispatcher) {
            super.init(dispatcher: dispatcher, keychainWrapper: KeychainWrapper.standard)

            self.disposeBag = DisposeBag()
        }

        override var syncState: Observable<SyncState> {
            return self.syncStateStub.asObservable()
        }

        let listStub = ReplaySubject<[LoginRecord]>.create(bufferSize: 1)
        override var list: Observable<[LoginRecord]> {
            return self.listStub.asObservable()
        }
    }

    class FakeItemListDisplayStore: ItemListDisplayStore {
        let listDisplayStub = ReplaySubject<ItemListDisplayAction>.create(bufferSize: 1)

        override var listDisplay: Observable<ItemListDisplayAction> {
            return self.listDisplayStub.asObservable()
        }
    }

    private var dispatcher: FakeDispatcher!
    private var sizeClassStore: FakeSizeClassStore!
    private var lifecycleStore: FakeLifecycleStore!
    private var dataStore: FakeDataStore!
    private var routeStore: FakeRouteStore!
    private var itemListDisplayStore: FakeItemListDisplayStore!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: ItemDetailStore!

    override func spec() {
        describe("ItemDetailStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.lifecycleStore = FakeLifecycleStore()
                self.sizeClassStore = FakeSizeClassStore()
                self.routeStore = FakeRouteStore()
                self.dataStore = FakeDataStore(dispatcher: self.dispatcher)
                self.itemListDisplayStore = FakeItemListDisplayStore()
                self.subject = ItemDetailStore(
                        dispatcher: self.dispatcher,
                        dataStore: self.dataStore,
                        sizeClassStore: self.sizeClassStore,
                        lifecycleStore: self.lifecycleStore,
                        routeStore: self.routeStore,
                        itemListDisplayStore: self.itemListDisplayStore
                )
            }

            describe("itemDetailId") {
                var detailIdObserver = self.scheduler.createObserver(String.self)

                beforeEach {
                    detailIdObserver = self.scheduler.createObserver(String.self)

                    self.subject.itemDetailId
                            .subscribe(detailIdObserver)
                            .disposed(by: self.disposeBag)
                }

                it("initalizes to empty string") {
                    expect(detailIdObserver.events.count).to(equal(1))
                    expect(detailIdObserver.events.first!.value.element!).to(equal(""))
                }

                it("itemDetailHasId is false") {
                    expect(self.subject.itemDetailHasId).to(beFalse())
                }

                describe("MainRouteAction") {
                    describe(".list") {
                        beforeEach {
                            self.routeStore.routeEventsStub.onNext(MainRouteAction.list)
                        }

                        it("does nothing") {
                            expect(detailIdObserver.events.count).to(equal(1))
                        }

                        it("does not change itemDetailHasId") {
                            expect(self.subject.itemDetailHasId).to(beFalse())
                        }
                    }

                    describe(".detail") {
                        beforeEach {
                            self.routeStore.routeEventsStub.onNext(MainRouteAction.detail(itemId: "asdf"))
                        }

                        it("sets detailId") {
                            expect(detailIdObserver.events.count).to(equal(2))
                            expect(detailIdObserver.events.last!.value.element!).to(equal("asdf"))
                        }

                        it("sets itemDeatilHasId") {
                            expect(self.subject.itemDetailHasId).to(beTrue())
                        }
                    }
                }

                describe("ItemDeletedAction") {
                    beforeEach {
                        self.routeStore.routeEventsStub.onNext(MainRouteAction.detail(itemId: "1234"))
                        self.itemListDisplayStore.listDisplayStub.onNext(ItemDeletedAction(name: "Item", id: "1234"))
                    }

                    it("clears the detailId") {
                        expect(detailIdObserver.events.last!.value.element!).to(equal(""))
                    }
                }
            }

            describe("showFirstLogin") {
                describe("when showing sidebar") {
                    var detailIdObserver = self.scheduler.createObserver(String.self)

                    beforeEach {
                        self.dataStore.syncStateStub.onNext(SyncState.Synced)
                        self.dataStore.listStub.onNext([
                            LoginRecord(fromJSONDict: ["id": "5678", "hostname": "asdf", "username": "asdf", "password": "asdf"])
                        ])

                        detailIdObserver = self.scheduler.createObserver(String.self)

                        self.subject.itemDetailId
                                .subscribe(detailIdObserver)
                                .disposed(by: self.disposeBag)
                    }

                    describe("when there is a detailId set") {
                        beforeEach {
                            self.routeStore.routeEventsStub.onNext(MainRouteAction.detail(itemId: "1234"))
                            expect(detailIdObserver.events.count).to(equal(2))
                            self.sizeClassStore.shouldDisplaySidebarStub.onNext(true)
                        }

                        it("does not change detailId") {
                            expect(detailIdObserver.events.count).to(equal(2))
                        }
                    }

                    describe("when there is not a detailId set") {
                        beforeEach {
                            self.routeStore.routeEventsStub.onNext(MainRouteAction.detail(itemId: ""))
                            self.sizeClassStore.shouldDisplaySidebarStub.onNext(true)
                        }

                        it("sets the detailId") {
                            expect(detailIdObserver.events.count).to(equal(3))
                            expect(detailIdObserver.events.last!.value.element!).to(equal("5678"))
                        }
                    }
                }

                describe("when not showing sidebar") {
                    var detailIdObserver = self.scheduler.createObserver(String.self)

                    beforeEach {
                        self.dataStore.syncStateStub.onNext(SyncState.Synced)
                        self.dataStore.listStub.onNext([LoginRecord(fromJSONDict: ["id": "5678", "hostname": "asdf", "username": "asdf", "password": "asdf"])])

                        detailIdObserver = self.scheduler.createObserver(String.self)

                        self.subject.itemDetailId
                                .subscribe(detailIdObserver)
                                .disposed(by: self.disposeBag)

                        self.routeStore.routeEventsStub.onNext(MainRouteAction.detail(itemId: "1234"))
                        expect(detailIdObserver.events.count).to(equal(2))
                        self.sizeClassStore.shouldDisplaySidebarStub.onNext(false)
                    }

                    it("does not change detail id") {
                        expect(detailIdObserver.events.count).to(equal(2))
                    }
                }
            }

            describe("itemDetailDisplay") {
                var passwordRevealedObserver = self.scheduler.createObserver(Bool.self)

                beforeEach {
                    passwordRevealedObserver = self.scheduler.createObserver(Bool.self)

                    self.subject.passwordRevealed
                            .drive(passwordRevealedObserver)
                            .disposed(by: self.disposeBag)
                }

                it("passes through ItemDetailDisplayActions from the dispatcher") {
                    self.dispatcher.fakeRegistration.onNext(ItemDetailDisplayAction.togglePassword(displayed: true))

                    expect(passwordRevealedObserver.events.count).to(equal(2))
                    expect(passwordRevealedObserver.events.last!.value.element!).to(equal(true))
                }

                it("does not pass through non-ItemDetailDisplayActions") {
                    self.dispatcher.fakeRegistration.onNext(LoginRouteAction.welcome)

                    expect(passwordRevealedObserver.events.count).to(equal(1))
                }

                it("backgrounding actions toggle password revealed status") {
                    self.lifecycleStore.lifecycleEventsStub.onNext(.background)

                    expect(passwordRevealedObserver.events.count).to(equal(2))
                    expect(passwordRevealedObserver.events.last!.value.element!).to(equal(false))
                }
            }

        }
    }
}

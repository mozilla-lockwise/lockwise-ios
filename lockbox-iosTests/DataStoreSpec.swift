/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift
import RxBlocking

@testable import Lockbox

class DataStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    private var scheduler: TestScheduler = TestScheduler(initialClock: 1)
    private var disposeBag = DisposeBag()

    private var dispatcher: FakeDispatcher!
    var subject: DataStore!

    override func spec() {
        describe("DataStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = DataStore(dispatcher: self.dispatcher)
            }

            describe("onItemList") {
                var itemListObserver = self.scheduler.createObserver([Item].self)
                let itemList = [
                    Item.Builder()
                            .id("kljsdflkjsd")
                            .origins(["bowl.com"])
                            .build(),
                    Item.Builder()
                            .id("dqwkldsfkj")
                            .origins(["plate.com"])
                            .build()
                ]

                beforeEach {
                    itemListObserver = self.scheduler.createObserver([Item].self)

                    self.subject.onItemList
                            .subscribe(itemListObserver)
                            .disposed(by: self.disposeBag)

                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.list(list: itemList))
                }

                it("pushes dispatched lists to observers") {
                    expect(itemListObserver.events.last).notTo(beNil())
                    expect(itemListObserver.events.last!.value.element).to(equal(itemList))
                }

                it("doesn't push the same list twice in a row") {
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.list(list: itemList))
                    expect(itemListObserver.events.count).to(equal(1))
                }

                it("pushes subsequent different lists") {
                    let newItemList = [Item.Builder().id("wwkjlkjm").build()] + itemList
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.list(list: newItemList))

                    expect(itemListObserver.events.count).to(equal(2))
                }

                it("does do anything with non-datastore actions") {
                    self.dispatcher.fakeRegistration.onNext(LoginRouteAction.fxa)
                    expect(itemListObserver.events.count).to(equal(1))
                }
            }

            describe("onItem") {
                var itemObserver = self.scheduler.createObserver(Item.self)
                let itemId = "fdsljkdsfkljdsfl"
                let item = Item.Builder()
                        .id(itemId)
                        .origins(["bowl.com"])
                        .build()
                let itemList = [
                    item,
                    Item.Builder()
                            .id("dqwkldsfkj")
                            .origins(["plate.com"])
                            .build()
                ]

                beforeEach {
                    itemObserver = self.scheduler.createObserver(Item.self)

                    self.subject.onItem(itemId)
                            .subscribe(itemObserver)
                            .disposed(by: self.disposeBag)

                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.list(list: itemList))
                }

                it("pushes dispatched lists to observers") {
                    expect(itemObserver.events.last).notTo(beNil())
                    expect(itemObserver.events.last!.value.element).to(equal(item))
                }

                it("doesn't push the item if it is unchanged") {
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.list(list: [item]))
                    expect(itemObserver.events.count).to(equal(1))
                }

                it("pushes the item again if it is changed") {
                    let changedItem = Item.Builder().id(itemId)
                            .origins(["cat.com"]).build()
                    let newItemList = [changedItem, Item.Builder().id("fdssdf").build()]
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.list(list: newItemList))

                    expect(itemObserver.events.count).to(equal(2))
                }

                it("does not do anything with non-datastore actions") {
                    self.dispatcher.fakeRegistration.onNext(LoginRouteAction.fxa)
                    expect(itemObserver.events.count).to(equal(1))
                }
            }

            describe("onInitialized") {
                var boolObserver = self.scheduler.createObserver(Bool.self)

                beforeEach {
                    boolObserver = self.scheduler.createObserver(Bool.self)

                    self.subject.onInitialized
                            .subscribe(boolObserver)
                            .disposed(by: self.disposeBag)

                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.initialized(initialized: true))
                }

                it("pushes dispatched initialized value to observers") {
                    expect(boolObserver.events.last).notTo(beNil())
                    expect(boolObserver.events.last!.value.element).to(equal(true))
                }

                it("doesn't push the same value twice in a row") {
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.initialized(initialized: true))
                    expect(boolObserver.events.count).to(equal(1))
                }

                it("pushes subsequent different values") {
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.initialized(initialized: false))

                    expect(boolObserver.events.count).to(equal(2))
                }

                it("does not do anything with non-datastore actions") {
                    self.dispatcher.fakeRegistration.onNext(LoginRouteAction.fxa)
                    expect(boolObserver.events.count).to(equal(1))
                }
            }

            describe("onOpened") {
                var boolObserver = self.scheduler.createObserver(Bool.self)

                beforeEach {
                    boolObserver = self.scheduler.createObserver(Bool.self)

                    self.subject.onOpened
                            .subscribe(boolObserver)
                            .disposed(by: self.disposeBag)

                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.opened(opened: true))
                }

                it("pushes dispatched opened value to observers") {
                    expect(boolObserver.events.last).notTo(beNil())
                    expect(boolObserver.events.last!.value.element).to(equal(true))
                }

                it("doesn't push the same value twice in a row") {
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.opened(opened: true))
                    expect(boolObserver.events.count).to(equal(1))
                }

                it("pushes subsequent different values") {
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.opened(opened: false))

                    expect(boolObserver.events.count).to(equal(2))
                }

                it("does not do anything with non-datastore actions") {
                    self.dispatcher.fakeRegistration.onNext(LoginRouteAction.fxa)
                    expect(boolObserver.events.count).to(equal(1))
                }
            }

            describe("onLocked") {
                var boolObserver = self.scheduler.createObserver(Bool.self)

                beforeEach {
                    boolObserver = self.scheduler.createObserver(Bool.self)

                    self.subject.onLocked
                            .subscribe(boolObserver)
                            .disposed(by: self.disposeBag)

                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.locked(locked: false))
                }

                it("pushes dispatched locked value to observers") {
                    expect(boolObserver.events.last).notTo(beNil())
                    expect(boolObserver.events.last!.value.element).to(equal(false))
                }

                it("doesn't push the same value twice in a row") {
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.locked(locked: false))
                    expect(boolObserver.events.count).to(equal(1))
                }

                it("pushes subsequent different values") {
                    self.dispatcher.fakeRegistration.onNext(DataStoreAction.locked(locked: true))

                    expect(boolObserver.events.count).to(equal(2))
                }

                it("does not do anything with non-datastore actions") {
                    self.dispatcher.fakeRegistration.onNext(LoginRouteAction.fxa)
                    expect(boolObserver.events.count).to(equal(1))
                }
            }
        }
    }
}

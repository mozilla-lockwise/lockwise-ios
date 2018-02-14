/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class ItemListPresenterSpec: QuickSpec {
    class FakeItemListView: ItemListViewProtocol {
        var displayItemsArgument: [Item]?
        var displayErrorArgument: Error?
        var displayEmptyStateMessagingCalled = false
        var hideEmptyStateMessagingCalled = false

        func displayItems(_ items: [Item]) {
            self.displayItemsArgument = items
        }

        func displayError(_ error: Error) {
            self.displayErrorArgument = error
        }

        func displayEmptyStateMessaging() {
            self.displayEmptyStateMessagingCalled = true
        }

        func hideEmptyStateMessaging() {
            self.hideEmptyStateMessagingCalled = true
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeActionArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeActionArgument = action
        }
    }

    class FakeDataStore: DataStore {
        var itemListObservable: TestableObservable<[Item]>?

        override var onItemList: Observable<[Item]> {
            return self.itemListObservable!.asObservable()
        }
    }

    private var view: FakeItemListView!
    private var routeActionHandler: FakeRouteActionHandler!
    private var dataStore: FakeDataStore!
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
    var subject: ItemListPresenter!

    override func spec() {
        describe("ItemListPresenter") {
            beforeEach {
                self.view = FakeItemListView()
                self.dataStore = FakeDataStore()
                self.routeActionHandler = FakeRouteActionHandler()

                self.subject = ItemListPresenter(
                        view: self.view,
                        routeActionHandler: self.routeActionHandler,
                        dataStore: self.dataStore
                )
            }

            describe(".onViewReady()") {
                describe("when the datastore pushes an empty list of items") {
                    beforeEach {
                        self.dataStore.itemListObservable = self.scheduler.createHotObservable([next(100, [])])
                        self.subject.onViewReady()
                        self.scheduler.start()
                    }

                    it("tells the view to display the empty lockbox message") {
                        expect(self.view.displayEmptyStateMessagingCalled).to(beTrue())
                    }
                }

                describe("when the datastore pushes a populated list of items") {
                    let items = [
                        Item.Builder().build(),
                        Item.Builder().build()
                    ]

                    beforeEach {
                        self.dataStore.itemListObservable = self.scheduler.createHotObservable([next(100, items)])
                        self.subject.onViewReady()
                        self.scheduler.start()
                    }

                    it("tells the view to display the items") {
                        expect(self.view.displayItemsArgument).notTo(beNil())
                        expect(self.view.displayItemsArgument).to(equal(items))
                    }

                    it("tells the view to hide the empty state messaging") {
                        expect(self.view.hideEmptyStateMessagingCalled).to(beTrue())
                    }
                }
            }

            describe("itemSelected") {
                describe("when the item has an id") {
                    let id = "fsjksdfjklsdfjlkdsf"

                    beforeEach {
                        let itemObservable = self.scheduler.createColdObservable([
                            next(100, Item.Builder().id(id).build())
                        ])

                        itemObservable
                                .bind(to: self.subject.itemSelectedObserver)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("tells the route action handler to display the detail view for the relevant item") {
                        expect(self.routeActionHandler.invokeActionArgument).notTo(beNil())
                        let argument = self.routeActionHandler.invokeActionArgument as! MainRouteAction
                        expect(argument).to(equal(MainRouteAction.detail(itemId: id)))
                    }
                }

                describe("when the item does not have an id") {
                    beforeEach {
                        let itemObservable = self.scheduler.createColdObservable([next(100, Item.Builder().build())])

                        itemObservable
                                .bind(to: self.subject.itemSelectedObserver)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("does nothing") {
                        expect(self.routeActionHandler.invokeActionArgument).to(beNil())
                    }
                }
            }
        }
    }
}

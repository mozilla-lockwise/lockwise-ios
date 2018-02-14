/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Quick
import Nimble
import RxTest
import RxSwift

@testable import Lockbox

class ItemListViewSpec: QuickSpec {

    class FakeCoder: NSCoder {
        func decodeObjectForKey(key: String) -> Any {
            return false
        }
    }

    class FakeItemListPresenter: ItemListPresenter {
        var onViewReadyCalled = false
        var fakeItemSelectedObserver: TestableObserver<Item>!

        override func onViewReady() {
            onViewReadyCalled = true
        }

        override var itemSelectedObserver: AnyObserver<Item> {
            return self.fakeItemSelectedObserver.asObserver()
        }
    }

    private var presenter: FakeItemListPresenter!
    private var scheduler = TestScheduler(initialClock: 0)
    var subject: ItemListView!

    override func spec() {
        describe("ItemListView") {
            beforeEach {
                let storyboard = UIStoryboard(name: "ItemList", bundle: Bundle.main)
                self.subject = storyboard.instantiateInitialViewController() as! ItemListView

                self.presenter = FakeItemListPresenter(view: self.subject)
                self.presenter.fakeItemSelectedObserver = self.scheduler.createObserver(Item.self)
                self.subject.presenter = self.presenter

                _ = UINavigationController(rootViewController: self.subject)
                self.subject.preloadView()
            }

            it("calls onviewready after loading the view") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            it("only has one section") {
                expect(self.subject.numberOfSections(in: self.subject.tableView)).to(equal(1))
            }

            describe(".displayItems()") {
                let items = [
                    Item.Builder()
                            .title("my fave item")
                            .entry(
                                    ItemEntry.Builder()
                                            .username("me")
                                            .build())
                            .build(),
                    Item.Builder()
                            .title("sum item")
                            .entry(
                                    ItemEntry.Builder()
                                            .build())
                            .build()
                ]

                beforeEach {
                    self.subject.displayItems(items)
                }

                it("configures the number of rows correctly") {
                    expect(self.subject.tableView(self.subject.tableView, numberOfRowsInSection: 0))
                            .to(equal(items.count))
                }

                it("configures cells correctly when the item has a username and a title") {
                    let cell = self.subject.tableView(
                            self.subject.tableView,
                            cellForRowAt: IndexPath(row: 0, section: 0)
                    ) as! ItemListCell

                    expect(cell.titleLabel!.text).to(equal(items[0].title))
                    expect(cell.detailLabel!.text).to(equal(items[0].entry.username))
                }

                it("configures cells correctly when the item has no username and a title") {
                    let cell = self.subject.tableView(
                            self.subject.tableView,
                            cellForRowAt: IndexPath(row: 1, section: 0)
                    ) as! ItemListCell

                    expect(cell.titleLabel!.text).to(equal(items[1].title))
                    expect(cell.detailLabel!.text).to(equal("(no username)"))
                }
            }

            describe("displayEmptyStateMessaging") {
                beforeEach {
                    self.subject.displayEmptyStateMessaging()
                }

                it("adds the empty list view to the background view") {
                    expect(self.subject.tableView.backgroundView?.subviews.count).to(equal(1))
                }
            }

            describe("hideEmptyStateMessaging") {
                beforeEach {
                    self.subject.hideEmptyStateMessaging()
                }

                it("removes the empty list view from the background view") {
                    expect(self.subject.tableView.backgroundView?.subviews.count).to(equal(0))
                }
            }

            describe("tapping a row") {
                let items = [
                    Item.Builder()
                            .title("my fave item")
                            .entry(
                                    ItemEntry.Builder()
                                            .username("me")
                                            .build())
                            .build()
                ]

                beforeEach {
                    self.subject.displayItems(items)
                    (self.subject.tableView.delegate!).tableView!(self.subject.tableView, didSelectRowAt: [0, 0])
                }

                it("tells the presenter") {
                    expect(self.presenter.fakeItemSelectedObserver.events.first!.value.element).to(equal(items.first))
                }
            }
        }
    }
}

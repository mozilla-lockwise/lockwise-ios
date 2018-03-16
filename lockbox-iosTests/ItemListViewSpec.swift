/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Quick
import Nimble
import RxTest
import RxCocoa
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
        var fakeItemSelectedObserver: TestableObserver<String?>!
        var fakeFilterTextObserver: TestableObserver<String>!
        var fakeSortingButtonObserver: TestableObserver<Void>!

        override func onViewReady() {
            onViewReadyCalled = true
        }

        override var itemSelectedObserver: AnyObserver<String?> {
            return self.fakeItemSelectedObserver.asObserver()
        }

        override var filterTextObserver: AnyObserver<String> {
            return self.fakeFilterTextObserver.asObserver()
        }

        override var sortingButtonObserver: AnyObserver<Void> {
            return self.fakeSortingButtonObserver.asObserver()
        }
    }

    private var presenter: FakeItemListPresenter!
    private var scheduler = TestScheduler(initialClock: 0)
    var subject: ItemListView!

    override func spec() {
        describe("ItemListView") {
            beforeEach {
                let storyboard = UIStoryboard(name: "ItemList", bundle: Bundle.main)
                self.subject = storyboard.instantiateViewController(withIdentifier: "itemlist") as! ItemListView

                self.presenter = FakeItemListPresenter(view: self.subject)
                self.presenter.fakeItemSelectedObserver = self.scheduler.createObserver(String?.self)
                self.presenter.fakeFilterTextObserver = self.scheduler.createObserver(String.self)
                self.presenter.fakeSortingButtonObserver = self.scheduler.createObserver(Void.self)
                self.subject.presenter = self.presenter

                _ = UINavigationController(rootViewController: self.subject)
                self.subject.preloadView()
            }

            it("has the correct statusbarstyle") {
                expect(self.subject.preferredStatusBarStyle).to(equal(UIStatusBarStyle.lightContent))
            }

            it("calls onviewready after loading the view") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            describe(".bind(items:)") {
                let item1Title = "item1"
                let item1Username = "bleh"
                let item2Title = "sum item"
                let item2Username = "meh"
                let items = [
                    ItemListCellConfiguration.Search,
                    ItemListCellConfiguration.Item(title: item1Title, username: item1Username, id: "fdssdfdfs"),
                    ItemListCellConfiguration.Item(title: item2Title, username: item2Username, id: "sdfsdads")
                ]

                beforeEach {
                    self.subject.bind(items: Driver.just([ItemSectionModel(model: 0, items: items)]))
                }

                it("configures the number of rows correctly") {
                    expect(self.subject.tableView.dataSource!.tableView(self.subject.tableView, numberOfRowsInSection: 0))
                            .to(equal(items.count))
                }

                it("configures the search cell correctly") {
                    let cell = self.subject.tableView.dataSource!.tableView(
                            self.subject.tableView,
                            cellForRowAt: IndexPath(row: 0, section: 0)
                    ) as! FilterCell

                    let filterText = "yum"
                    cell.filterTextField.text = filterText
                    cell.filterTextField.sendActions(for: .valueChanged)

                    expect(self.presenter.fakeFilterTextObserver.events.last!.value.element).to(equal(filterText))
                }

                it("configures cells correctly when the item has a username and a title") {
                    let cell = self.subject.tableView.dataSource!.tableView(
                            self.subject.tableView,
                            cellForRowAt: IndexPath(row: 1, section: 0)
                    ) as! ItemListCell

                    expect(cell.titleLabel!.text).to(equal(item1Title))
                    expect(cell.detailLabel!.text).to(equal(item1Username))
                }

                it("configures cells correctly when the item has no username and a title") {
                    let cell = self.subject.tableView.dataSource!.tableView(
                            self.subject.tableView,
                            cellForRowAt: IndexPath(row: 2, section: 0)
                    ) as! ItemListCell

                    expect(cell.titleLabel!.text).to(equal(item2Title))
                    expect(cell.detailLabel!.text).to(equal(item2Username))
                }
            }

            describe("bind(sortingButtonTitle:)") {
                let newTitle = "yum"

                beforeEach {
                    self.subject.bind(sortingButtonTitle: Driver.just(newTitle))
                }

                it("configures the sorting button title") {
                    let button = self.subject.navigationItem.leftBarButtonItem!.customView as! UIButton

                    expect(button.currentTitle).to(equal(newTitle))
                }
            }

            describe("displayEmptyStateMessaging") {
                beforeEach {
                    self.subject.displayEmptyStateMessaging()
                }

                it("adds the empty list view to the background view") {
                    expect(self.subject.tableView.backgroundView?.subviews.count).to(equal(1))
                }

                it("hides the left bar button item") {
                    expect(self.subject.navigationItem.leftBarButtonItem!.customView!.isHidden).to(beTrue())
                }
            }

            describe("hideEmptyStateMessaging") {
                beforeEach {
                    self.subject.displayEmptyStateMessaging()
                    self.subject.hideEmptyStateMessaging()
                }

                it("removes the empty list view from the background view") {
                    expect(self.subject.tableView.backgroundView?.subviews.count).toEventually(equal(0))
                }

                it("shows the left bar button item") {
                    expect(self.subject.navigationItem.leftBarButtonItem!.customView!.isHidden).to(beFalse())
                }
            }

            describe("tapping a row") {
                let id = "fdssdfdfs"
                let items = [
                    ItemListCellConfiguration.Search,
                    ItemListCellConfiguration.Item(title: "item1", username: "bleh", id: id)
                ]

                beforeEach {
                    self.subject.bind(items: Driver.just([ItemSectionModel(model: 0, items: items)]))
                }

                describe("tapping an item row") {
                    beforeEach {
                        (self.subject.tableView.delegate!).tableView!(self.subject.tableView, didSelectRowAt: [0, 1])

                    }

                    it("tells the presenter the item id") {
                        expect(self.presenter.fakeItemSelectedObserver.events.first!.value.element!).to(equal(id))
                    }
                }

                describe("tapping the search row") {
                    beforeEach {
                        (self.subject.tableView.delegate!).tableView!(self.subject.tableView, didSelectRowAt: [0, 0])
                    }

                    it("tells the presenter a nil item id") {
                        expect(self.presenter.fakeItemSelectedObserver.events.first!.value.element!).to(beNil())
                    }
                }
            }

            describe("tapping the sorting button") {
                beforeEach {
                    let button = self.subject.navigationItem.leftBarButtonItem!.customView as! UIButton

                    button.sendActions(for: .touchUpInside)
                }

                it("tells the presenter") {
                    expect(self.presenter.fakeSortingButtonObserver.events.count).to(equal(1))
                }
            }

            describe("ItemListCell") {
                let items = [
                    ItemListCellConfiguration.Item(title: "item1", username: "bleh", id: "fdssdfdfs")
                ]

                beforeEach {
                    self.subject.bind(items: Driver.just([ItemSectionModel(model: 0, items: items)]))
                }

                it("highlights correctly") {
                    let cell = self.subject.tableView.dataSource!.tableView(
                            self.subject.tableView,
                            cellForRowAt: [0, 0]
                    ) as! ItemListCell

                    cell.setHighlighted(true, animated: false)
                    expect(cell.backgroundColor).to(equal(Constant.color.tableViewCellHighlighted))

                    cell.setHighlighted(false, animated: false)
                    expect(cell.backgroundColor).to(equal(UIColor.white))
                }
            }

            describe("FilterCell") {
                beforeEach {
                    self.subject.bind(items: Driver.just([ItemSectionModel(model: 0, items: [ItemListCellConfiguration.Search])]))
                }

                it("disposes of its bag when preparing for reuse") {
                    let cell = self.subject.tableView.dataSource!.tableView(
                            self.subject.tableView,
                            cellForRowAt: IndexPath(row: 0, section: 0)
                    ) as! FilterCell

                    let disposeBag = cell.disposeBag

                    cell.prepareForReuse()

                    expect(cell.disposeBag === disposeBag).notTo(beTrue())
                }
            }
        }

        describe("ItemListCellConfiguration") {
            describe("IdentifiableType") {
                it("uses either the item title or just returns `search`") {
                    expect(ItemListCellConfiguration.Search.identity).to(equal("search"))
                    expect(ItemListCellConfiguration.Item(title: "something", username: "", id: nil).identity).to(equal("something"))
                }
            }

            describe("equality") {
                it("search is always the same as search") {
                    expect(ItemListCellConfiguration.Search).to(equal(ItemListCellConfiguration.Search))
                }

                it("items are the same if the titles & usernames are the same") {
                    expect(ItemListCellConfiguration.Item(title: "blah", username: "", id: nil)).notTo(equal(ItemListCellConfiguration.Item(title: "blah", username: "meh", id: nil)))
                    expect(ItemListCellConfiguration.Item(title: "blah", username: "meh", id: nil)).to(equal(ItemListCellConfiguration.Item(title: "blah", username: "meh", id: nil)))
                    expect(ItemListCellConfiguration.Item(title: "meh", username: "meh", id: nil)).notTo(equal(ItemListCellConfiguration.Item(title: "blah", username: "meh", id: nil)))
                    expect(ItemListCellConfiguration.Item(title: "meh", username: "blah", id: nil)).notTo(equal(ItemListCellConfiguration.Item(title: "blah", username: "meh", id: nil)))
                }

                it("search and item are never the same") {
                    expect(ItemListCellConfiguration.Search).notTo(equal(ItemListCellConfiguration.Item(title: "", username: "", id: nil)))
                }
            }
        }
    }
}

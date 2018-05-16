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
        var fakeCancelObserver: TestableObserver<Void>!

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

        override var filterCancelObserver: AnyObserver<Void> {
            return self.fakeCancelObserver.asObserver()
        }
    }

    private var presenter: FakeItemListPresenter!
    private var scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
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
                self.presenter.fakeCancelObserver = self.scheduler.createObserver(Void.self)
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
                    LoginListCellConfiguration.Search,
                    LoginListCellConfiguration.Item(title: item1Title, username: item1Username, guid: "fdssdfdfs"),
                    LoginListCellConfiguration.Item(title: item2Title, username: item2Username, guid: "sdfsdads")
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

            describe("new events to the sortingButtonEnabled observer") {
                beforeEach {
                    Observable.just(false).bind(to: self.subject.sortingButtonEnabled!).disposed(by: self.disposeBag)
                }

                it("changes the corresponding property on the sorting button") {
                    let button = self.subject.navigationItem.leftBarButtonItem!.customView as! UIButton

                    expect(button.isEnabled).to(beFalse())
                }
            }

            describe("displayEmptyStateMessaging") {
                beforeEach {
                    self.subject.displayEmptyStateMessaging()
                }

                it("hides the left bar button item") {
                    expect(self.subject.navigationItem.leftBarButtonItem!.customView!.isHidden).to(beTrue())
                }

                it("disables scrolling") {
                    expect(self.subject.tableView.isScrollEnabled).to(beFalse())
                }
            }

            describe("hideEmptyStateMessaging") {
                beforeEach {
                    self.subject.displayEmptyStateMessaging()
                    self.subject.hideEmptyStateMessaging()
                }

                it("shows the left bar button item") {
                    expect(self.subject.navigationItem.leftBarButtonItem!.customView!.isHidden).to(beFalse())
                }

                it("enables scrolling") {
                    expect(self.subject.tableView.isScrollEnabled).to(beTrue())
                }
            }

            describe("tapping a row") {
                let id = "fdssdfdfs"
                let items = [
                    LoginListCellConfiguration.Search,
                    LoginListCellConfiguration.Item(title: "item1", username: "bleh", guid: id),
                    LoginListCellConfiguration.ListPlaceholder
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

                describe("tapping the search row") {
                    beforeEach {
                        (self.subject.tableView.delegate!).tableView!(self.subject.tableView, didSelectRowAt: [0, 2])
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
                    LoginListCellConfiguration.Item(title: "item1", username: "bleh", guid: "fdssdfdfs")
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
                var cell: FilterCell!

                beforeEach {
                    self.subject.bind(items: Driver.just([ItemSectionModel(model: 0, items: [LoginListCellConfiguration.Search])]))
                    cell = self.subject.tableView.dataSource!.tableView(
                        self.subject.tableView,
                        cellForRowAt: IndexPath(row: 0, section: 0)
                        ) as! FilterCell
                }

                it("disposes of its bag when preparing for reuse") {
                    let disposeBag = cell.disposeBag

                    cell.prepareForReuse()

                    expect(cell.disposeBag === disposeBag).notTo(beTrue())
                }

                describe("displayFilterCancelButton") {
                    beforeEach {
                        self.subject.displayFilterCancelButton()
                    }
                    it("shows the button") {
                        cell = self.subject.tableView.cellForRow(at: [0, 0]) as! FilterCell
                        expect(cell.cancelButton.isHidden).toEventually(beFalse())
                    }
                }

                describe("hideFilterCancelButton") {
                    beforeEach {
                        self.subject.hideFilterCancelButton()
                    }

                    it("hides the button") {
                        cell = self.subject.tableView.cellForRow(at: [0, 0]) as! FilterCell
                        expect(cell.cancelButton.isHidden).to(beTrue())
                    }
                }
            }
        }

        describe("LoginListCellConfiguration") {
            describe("IdentifiableType") {
                it("uses either the item title or just returns `search`") {
                    expect(LoginListCellConfiguration.Search.identity).to(equal("search"))
                    let guid = "sfsdsdffsd"
                    expect(LoginListCellConfiguration.Item(title: "something", username: "", guid: guid).identity).to(equal(guid))
                }
            }

            describe("equality") {
                it("search is always the same as search") {
                    expect(LoginListCellConfiguration.Search).to(equal(LoginListCellConfiguration.Search))
                }

                it("items are the same if the titles & usernames are the same") {
                    expect(LoginListCellConfiguration.Item(title: "blah", username: "", guid: nil)).notTo(equal(LoginListCellConfiguration.Item(title: "blah", username: "meh", guid: nil)))
                    expect(LoginListCellConfiguration.Item(title: "blah", username: "meh", guid: nil)).to(equal(LoginListCellConfiguration.Item(title: "blah", username: "meh", guid: nil)))
                    expect(LoginListCellConfiguration.Item(title: "meh", username: "meh", guid: nil)).notTo(equal(LoginListCellConfiguration.Item(title: "blah", username: "meh", guid: nil)))
                    expect(LoginListCellConfiguration.Item(title: "meh", username: "blah", guid: nil)).notTo(equal(LoginListCellConfiguration.Item(title: "blah", username: "meh", guid: nil)))
                }

                it("search and item are never the same") {
                    expect(LoginListCellConfiguration.Search).notTo(equal(LoginListCellConfiguration.Item(title: "", username: "", guid: nil)))
                }
            }
        }
    }
}

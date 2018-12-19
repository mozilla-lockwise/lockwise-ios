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
        var fakeCancelObserver: TestableObserver<Void>!
        var fakeEditEndedObserver: TestableObserver<Void>!
        var fakeListSortedObserver: TestableObserver<Setting.ItemListSort>!

        override func onViewReady() {
            onViewReadyCalled = true
        }

        override var itemSelectedObserver: AnyObserver<String?> {
            return self.fakeItemSelectedObserver.asObserver()
        }

        override var filterTextObserver: AnyObserver<String> {
            return self.fakeFilterTextObserver.asObserver()
        }

        override var listSortedObserver: AnyObserver<Setting.ItemListSort> {
            return self.fakeListSortedObserver.asObserver()
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
                self.subject = storyboard.instantiateViewController(withIdentifier: "itemlist") as? ItemListView

                self.presenter = FakeItemListPresenter(view: self.subject)
                self.presenter.fakeItemSelectedObserver = self.scheduler.createObserver(String?.self)
                self.presenter.fakeFilterTextObserver = self.scheduler.createObserver(String.self)
                self.presenter.fakeCancelObserver = self.scheduler.createObserver(Void.self)
                self.presenter.fakeEditEndedObserver = self.scheduler.createObserver(Void.self)
                self.presenter.fakeListSortedObserver = self.scheduler.createObserver(Setting.ItemListSort.self)
                self.subject.basePresenter = self.presenter

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
                describe("typical login items") {
                    let item1Title = "item1"
                    let item1Username = "bleh"
                    let item2Title = "sum item"
                    let item2Username = "meh"
                    let items = [
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

                    it("configures cells correctly when the item has a username and a title") {
                        let cell = self.subject.tableView.dataSource!.tableView(
                                self.subject.tableView,
                                cellForRowAt: IndexPath(row: 0, section: 0)
                        ) as! ItemListCell

                        expect(cell.titleLabel!.text).to(equal(item1Title))
                        expect(cell.detailLabel!.text).to(equal(item1Username))
                    }

                    it("configures cells correctly when the item has no username and a title") {
                        let cell = self.subject.tableView.dataSource!.tableView(
                                self.subject.tableView,
                                cellForRowAt: IndexPath(row: 1, section: 0)
                        ) as! ItemListCell

                        expect(cell.titleLabel!.text).to(equal(item2Title))
                        expect(cell.detailLabel!.text).to(equal(item2Username))
                    }
                }

                describe("syncing list placeholder") {
                    beforeEach {
                        self.subject.bind(items: Driver.just(
                                        [ItemSectionModel(model: 0, items: [LoginListCellConfiguration.SyncListPlaceholder])]
                                ))
                    }

                    it("configures the sync list placeholder") {
                        let cell = self.subject.tableView.dataSource!.tableView(
                                self.subject.tableView,
                                cellForRowAt: IndexPath(row: 0, section: 0)
                        )

                        expect(cell).notTo(beNil())
                    }
                }

                describe("empty list placeholder") {
                    var learnMoreObserver = self.scheduler.createObserver(Void.self)

                    beforeEach {
                        learnMoreObserver = self.scheduler.createObserver(Void.self)

                        self.subject.bind(items: Driver.just(
                                [ItemSectionModel(model: 0, items: [LoginListCellConfiguration.EmptyListPlaceholder(learnMoreObserver: learnMoreObserver.asObserver())])]
                        ))
                    }

                    it("configures the empty list placeholder") {
                        let cell = self.subject.tableView.dataSource!.tableView(
                                self.subject.tableView,
                                cellForRowAt: IndexPath(row: 0, section: 0)
                        ) as? EmptyPlaceholderCell

                        expect(cell).notTo(beNil())
                    }

                    it("configures the learn more button") {
                        let cell = self.subject.tableView.dataSource!.tableView(
                                self.subject.tableView,
                                cellForRowAt: IndexPath(row: 0, section: 0)
                        ) as! EmptyPlaceholderCell

                        cell.learnMoreButton.sendActions(for: .touchUpInside)

                        expect(learnMoreObserver.events.count).to(equal(1))
                    }
                }

                describe("no results placeholder") {
                    var learnMoreObserver = self.scheduler.createObserver(Void.self)

                    beforeEach {
                        learnMoreObserver = self.scheduler.createObserver(Void.self)
                        self.subject.bind(items: Driver.just(
                            [ItemSectionModel(model: 0, items: [LoginListCellConfiguration.NoResults(learnMoreObserver: learnMoreObserver.asObserver())])]))
                    }

                    it("configures the no results placeholder") {
                        let cell = self.subject.tableView.dataSource!.tableView(
                            self.subject.tableView,
                            cellForRowAt: IndexPath(row: 0, section: 0)
                        )

                        expect(cell).notTo(beNil())
                    }

                    it("configures the learn more button") {
                        let cell = self.subject.tableView.dataSource!.tableView(
                            self.subject.tableView,
                            cellForRowAt: IndexPath(row: 0, section: 0)
                            ) as! NoResultsCell

                        cell.learnMoreButton.sendActions(for: .touchUpInside)

                        expect(learnMoreObserver.events.count).to(equal(1))
                    }
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

            describe("tapping a row") {
                let id = "fdssdfdfs"
                let items = [
                    LoginListCellConfiguration.Item(title: "item1", username: "bleh", guid: id),
                    LoginListCellConfiguration.SyncListPlaceholder
                ]

                beforeEach {
                    self.subject.bind(items: Driver.just([ItemSectionModel(model: 0, items: items)]))
                }

                describe("tapping an item row") {
                    beforeEach {
                        (self.subject.tableView.delegate!).tableView!(self.subject.tableView, didSelectRowAt: [0, 0])

                    }

                    it("tells the presenter the item id") {
                        expect(self.presenter.fakeItemSelectedObserver.events.first!.value.element!).to(equal(id))
                    }
                }
            }

            describe("tapping the sorting button") {
                var buttonObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    buttonObserver = self.scheduler.createObserver(Void.self)

                    self.subject.onSortingButtonPressed!
                        .subscribe(buttonObserver)
                        .disposed(by: self.disposeBag)

                    let sortingButton = self.subject.navigationItem.leftBarButtonItem!.customView as! UIButton
                    sortingButton.sendActions(for: .touchUpInside)
                }

                it("tells observers about button taps") {
                    expect(buttonObserver.events.count).to(be(1))
                }
            }

            describe("tapping the settings button") {
                var buttonObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    buttonObserver = self.scheduler.createObserver(Void.self)

                    self.subject.onSettingsButtonPressed!
                        .subscribe(buttonObserver)
                        .disposed(by: self.disposeBag)

                    let settingsButton = self.subject.navigationItem.rightBarButtonItem!.customView as! UIButton
                    settingsButton.sendActions(for: .touchUpInside)
                }

                it("tells observers about button taps") {
                    expect(buttonObserver.events.count).to(be(1))
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
        }

        describe("LoginListCellConfiguration") {
            describe("IdentifiableType") {
                it("uses either the item title or just returns a static string") {
                    let guid = "sfsdsdffsd"
                    expect(LoginListCellConfiguration.Item(title: "something", username: "", guid: guid).identity).to(equal(guid))
                    expect(LoginListCellConfiguration.SyncListPlaceholder.identity).to(equal("syncplaceholder"))
                    let fakeObserver = self.scheduler.createObserver(Void.self).asObserver()
                    expect(LoginListCellConfiguration.EmptyListPlaceholder(learnMoreObserver: fakeObserver).identity).to(equal("emptyplaceholder"))
                }
            }
        }

        describe("setFilter to true") {
            beforeEach {
                self.subject.setFilterEnabled(enabled: true)
            }

            it("enables the search bar") {
                expect(self.subject.searchController?.searchBar.isUserInteractionEnabled).toEventually(beTrue())
            }
        }

        describe("setFilter to false") {
            beforeEach {
                self.subject.setFilterEnabled(enabled: false)
            }

            it("disables the search bar") {
                expect(self.subject.searchController?.searchBar.isUserInteractionEnabled).toEventually(beFalse())
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxCocoa
import RxTest

@testable import Lockbox

class ItemListPresenterSpec: QuickSpec {
    class FakeItemListView: ItemListViewProtocol {
        var itemsObserver: TestableObserver<[ItemSectionModel]>!
        var sortingButtonTitleObserver: TestableObserver<String>!
        var displayEmptyStateMessagingCalled = false
        var hideEmptyStateMessagingCalled = false
        let disposeBag = DisposeBag()

        var displayOptionSheetButtons: [OptionSheetButtonConfiguration]?
        var displayOptionSheetTitle: String?

        func bind(items: Driver<[ItemSectionModel]>) {
            items.drive(itemsObserver).disposed(by: self.disposeBag)
        }

        func bind(sortingButtonTitle: Driver<String>) {
            sortingButtonTitle.drive(sortingButtonTitleObserver).disposed(by: self.disposeBag)
        }

        func displayEmptyStateMessaging() {
            self.displayEmptyStateMessagingCalled = true
        }

        func hideEmptyStateMessaging() {
            self.hideEmptyStateMessagingCalled = true
        }

        func displayOptionSheet(buttons: [OptionSheetButtonConfiguration], title: String?) {
            self.displayOptionSheetButtons = buttons
            self.displayOptionSheetTitle = title
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeActionArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeActionArgument = action
        }
    }

    class FakeItemListDisplayActionHandler: ItemListDisplayActionHandler {
        var invokeActionArgument: [ItemListDisplayAction] = []

        override func invoke(_ action: ItemListDisplayAction) {
            self.invokeActionArgument.append(action)
        }
    }

    class FakeDataStore: DataStore {
        var itemListObservable: TestableObservable<[Item]>?

        override var onItemList: Observable<[Item]> {
            return self.itemListObservable!.asObservable()
        }
    }

    class FakeItemListDisplayStore: ItemListDisplayStore {
        var itemListDisplaySubject = PublishSubject<ItemListDisplayAction>()

        override var listDisplay: Observable<ItemListDisplayAction> {
            return self.itemListDisplaySubject.asObservable()
        }
    }

    private var view: FakeItemListView!
    private var routeActionHandler: FakeRouteActionHandler!
    private var itemListDisplayActionHandler: FakeItemListDisplayActionHandler!
    private var dataStore: FakeDataStore!
    private var itemListDisplayStore: FakeItemListDisplayStore!
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
    var subject: ItemListPresenter!

    override func spec() {
        describe("ItemListPresenter") {
            beforeEach {
                self.view = FakeItemListView()
                self.routeActionHandler = FakeRouteActionHandler()
                self.itemListDisplayActionHandler = FakeItemListDisplayActionHandler()
                self.dataStore = FakeDataStore()
                self.itemListDisplayStore = FakeItemListDisplayStore()
                self.view.itemsObserver = self.scheduler.createObserver([ItemSectionModel].self)
                self.view.sortingButtonTitleObserver = self.scheduler.createObserver(String.self)

                self.subject = ItemListPresenter(
                        view: self.view,
                        routeActionHandler: self.routeActionHandler,
                        itemListDisplayActionHandler: self.itemListDisplayActionHandler,
                        dataStore: self.dataStore,
                        itemListDisplayStore: self.itemListDisplayStore
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
                    let title1 = "meow"
                    let title2 = "aaaaaa"
                    let username = "cats@cats.com"

                    let id1 = "fdsdfsfdsfds"
                    let id2 = "ghfhghgff"
                    let items = [
                        Item.Builder()
                                .title(title1).entry(
                                        ItemEntry.Builder()
                                                .username(username)
                                                .build()
                                )
                                .lastUsed("1970-01-01T00:03:20.4500Z")
                                .id(id1)
                                .build(),
                        Item.Builder()
                                .origins(["www.dogs.com"])
                                .lastUsed("1970-01-01T00:02:20.4500Z")
                                .id(id2)
                                .build(),
                        Item.Builder()
                                .title(title2)
                                .build()
                    ]

                    beforeEach {
                        self.dataStore.itemListObservable = self.scheduler.createHotObservable([next(100, items)])
                        self.subject.onViewReady()
                        self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListFilterAction(filteringText: ""))
                        self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListSortingAction.alphabetically)
                        self.scheduler.start()
                    }

                    it("tells the view to hide the empty state messaging") {
                        expect(self.view.hideEmptyStateMessagingCalled).to(beTrue())
                    }

                    it("tells the view to display the items in alphabetic order by title") {
                        let expectedItemConfigurations = [
                            ItemListCellConfiguration.Search,
                            ItemListCellConfiguration.Item(title: "", username: Constant.string.usernamePlaceholder, id: id2),
                            ItemListCellConfiguration.Item(title: title2, username: Constant.string.usernamePlaceholder, id: nil),
                            ItemListCellConfiguration.Item(title: title1, username: username, id: id1)
                        ]
                        expect(self.view.itemsObserver.events.first!.value.element).notTo(beNil())
                        let configuration = self.view.itemsObserver.events.first!.value.element!
                        expect(configuration.first!.items).to(equal(expectedItemConfigurations))
                    }

                    describe("when text is entered into the search bar") {
                        describe("when the text matches an item's username") {
                            beforeEach {
                                self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListFilterAction(filteringText: "cat"))
                            }

                            it("updates the view with the appropriate items") {
                                let expectedItemConfigurations = [
                                    ItemListCellConfiguration.Search,
                                    ItemListCellConfiguration.Item(title: title1, username: username, id: id1)
                                ]

                                expect(self.view.itemsObserver.events.last!.value.element).notTo(beNil())
                                let configuration = self.view.itemsObserver.events.last!.value.element!
                                expect(configuration.first!.items).to(equal(expectedItemConfigurations))
                            }
                        }

                        describe("when the text matches an item's origins") {
                            beforeEach {
                                self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListFilterAction(filteringText: "dog"))
                            }

                            it("updates the view with the appropriate items") {
                                let expectedItemConfigurations = [
                                    ItemListCellConfiguration.Search,
                                    ItemListCellConfiguration.Item(title: "", username: Constant.string.usernamePlaceholder, id: id2)
                                ]

                                expect(self.view.itemsObserver.events.last!.value.element).notTo(beNil())
                                let configuration = self.view.itemsObserver.events.last!.value.element!
                                expect(configuration.first!.items).to(equal(expectedItemConfigurations))
                            }
                        }

                        describe("when the text matches an item's title") {
                            beforeEach {
                                self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListFilterAction(filteringText: "me"))
                            }

                            it("updates the view with the appropriate items") {
                                let expectedItemConfigurations = [
                                    ItemListCellConfiguration.Search,
                                    ItemListCellConfiguration.Item(title: title1, username: username, id: id1)
                                ]

                                expect(self.view.itemsObserver.events.last!.value.element).notTo(beNil())
                                let configuration = self.view.itemsObserver.events.last!.value.element!
                                expect(configuration.first!.items).to(equal(expectedItemConfigurations))
                            }
                        }
                    }

                    describe("when sorting method switches to recently used") {
                        beforeEach {
                            self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListSortingAction.recentlyUsed)
                        }

                        it("pushes the new configuration with the items") {
                            let expectedItemConfigurations = [
                                ItemListCellConfiguration.Search,
                                ItemListCellConfiguration.Item(title: title1, username: username, id: id1),
                                ItemListCellConfiguration.Item(title: "", username: Constant.string.usernamePlaceholder, id: id2),
                                ItemListCellConfiguration.Item(title: title2, username: Constant.string.usernamePlaceholder, id: nil)
                            ]
                            expect(self.view.itemsObserver.events.last!.value.element).notTo(beNil())
                            let configuration = self.view.itemsObserver.events.last!.value.element!
                            expect(configuration.last!.items).to(equal(expectedItemConfigurations))
                        }
                    }
                }
            }

            describe("filterText") {
                let text = "entered text"

                beforeEach {
                    let textObservable = self.scheduler.createColdObservable([next(40, text)])

                    textObservable.bind(to: self.subject.filterTextObserver).disposed(by: self.disposeBag)

                    self.scheduler.start()
                }

                it("dispatches the filtertext item list display action") {
                    let action = self.itemListDisplayActionHandler.invokeActionArgument.popLast() as! ItemListFilterAction
                    expect(action.filteringText).to(equal(text))
                }
            }

            describe("itemSelected") {
                describe("when the item has an id") {
                    let id = "fsjksdfjklsdfjlkdsf"

                    beforeEach {
                        let itemObservable = self.scheduler.createColdObservable([
                            next(50, id)
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
                        let itemObservable: TestableObservable<String?> = self.scheduler.createColdObservable([next(50, nil)])

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

            describe("sortingButton") {
                beforeEach {
                    let voidObservable = self.scheduler.createColdObservable([next(50, ())])

                    voidObservable
                            .bind(to: self.subject.sortingButtonObserver)
                            .disposed(by: self.disposeBag)

                    self.scheduler.start()
                }

                it("tells the view to display an option sheet") {
                    expect(self.view.displayOptionSheetButtons).notTo(beNil())
                    expect(self.view.displayOptionSheetTitle).notTo(beNil())

                    expect(self.view.displayOptionSheetTitle).to(equal(Constant.string.sortEntries))
                }

                describe("tapping alphabetically") {
                    beforeEach {
                        self.view.displayOptionSheetButtons![0].tapObserver!.onNext(())
                    }

                    it("dispatches the alphabetically ItemListSortingAction") {
                        let action = self.itemListDisplayActionHandler.invokeActionArgument.popLast() as! ItemListSortingAction
                        expect(action).to(equal(ItemListSortingAction.alphabetically))
                    }
                }

                describe("tapping recently used") {
                    beforeEach {
                        self.view.displayOptionSheetButtons![1].tapObserver!.onNext(())
                    }

                    it("dispatches the alphabetically ItemListSortingAction") {
                        let action = self.itemListDisplayActionHandler.invokeActionArgument.popLast() as! ItemListSortingAction
                        expect(action).to(equal(ItemListSortingAction.recentlyUsed))
                    }
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxCocoa
import RxTest
import MozillaAppServices
import SwiftKeychainWrapper

@testable import Lockbox

class ItemListPresenterSpec: QuickSpec {
    class FakeItemListView: ItemListViewProtocol {
        var sortButton: UIBarButtonItem?
        var sortingButtonHidden: AnyObserver<Bool>?
        var itemsObserver: TestableObserver<[ItemSectionModel]>!
        var sortButtonEnableObserver: TestableObserver<Bool>!
        var tableViewScrollObserver: TestableObserver<Bool>!
        var sortingButtonTitleObserver: TestableObserver<String>!
        var scrollActionObserver: TestableObserver<ScrollAction>!
        var dismissSpinnerObserver: TestableObserver<Void>!
        let disposeBag = DisposeBag()
        var dismissKeyboardCalled = false
        var displaySpinnerCalled = false
        var scrollToTopCalled = false
        var pullToRefreshObserver: TestableObserver<Bool>!
        var fakeOnSettingsPressed = PublishSubject<Void>()
        var fakeOnSortingButtonPressed = PublishSubject<Void>()
        var fakeItemDeleted = PublishSubject<String>()
        var setFilterEnabledValue: Bool?
        var displayOptionSheetButtons: [AlertActionButtonConfiguration]?
        var temporaryAlertArgument: String?
        var deletedMessage: String?

        var displayOptionSheetTitle: String?
        func bind(items: Driver<[ItemSectionModel]>) {
            items.drive(itemsObserver).disposed(by: self.disposeBag)
        }

        func bind(sortingButtonTitle: Driver<String>) {
            sortingButtonTitle.drive(sortingButtonTitleObserver).disposed(by: self.disposeBag)
        }

        func bind(scrollAction: Driver<ScrollAction>) {
            scrollToTopCalled = true
            scrollAction.drive(scrollActionObserver).disposed(by: self.disposeBag)
        }

        func displayAlertController(buttons: [AlertActionButtonConfiguration], title: String?, message: String?, style: UIAlertController.Style, barButtonItem: UIBarButtonItem?) {
            self.displayOptionSheetButtons = buttons
            self.displayOptionSheetTitle = title
        }

        func displayTemporaryAlert(_ message: String, timeout: TimeInterval, icon: UIImage?) {
            self.temporaryAlertArgument = message
        }

        func dismissKeyboard() {
            self.dismissKeyboardCalled = true
        }

        var sortingButtonEnabled: AnyObserver<Bool>? {
            return self.sortButtonEnableObserver.asObserver()
        }

        var tableViewScrollEnabled: AnyObserver<Bool> {
            return self.tableViewScrollObserver.asObserver()
        }

        func displaySpinner(_ dismiss: Driver<Void>, bag: DisposeBag, message: String, completionMessage: String) {
            self.displaySpinnerCalled = true
            dismiss.drive(self.dismissSpinnerObserver).disposed(by: bag)
        }

        var pullToRefreshActive: AnyObserver<Bool>? {
            return self.pullToRefreshObserver?.asObserver()
        }

        var onSettingsButtonPressed: ControlEvent<Void>? {
            return ControlEvent<Void>(events: fakeOnSettingsPressed.asObservable())
        }

        var onSortingButtonPressed: ControlEvent<Void>? {
            return ControlEvent<Void>(events: fakeOnSortingButtonPressed.asObservable())
        }

        var itemDeleted: Observable<String> {
            return self.fakeItemDeleted.asObservable()
        }

        func setFilterEnabled(enabled: Bool) {
            self.setFilterEnabledValue = enabled
        }

        func showDeletedStatusAlert(message: String) {
            self.deletedMessage = message
        }
    }

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    class FakeDataStore: DataStore {
        var itemListStub: PublishSubject<[LoginRecord]>
        var syncStateStub: PublishSubject<SyncState>
        var storageStateStub: PublishSubject<LoginStoreState>
        var getStub: ReplaySubject<LoginRecord?>

        init(dispatcher: Dispatcher) {
            self.itemListStub = PublishSubject<[LoginRecord]>()
            self.syncStateStub = PublishSubject<SyncState>()
            self.storageStateStub = PublishSubject<LoginStoreState>()
            self.getStub = ReplaySubject<LoginRecord?>.create(bufferSize: 1)
            super.init(dispatcher: dispatcher, keychainWrapper: KeychainWrapper.standard)

            self.disposeBag = DisposeBag()
        }

        override var list: Observable<[LoginRecord]> {
            return self.itemListStub.asObservable()
        }

        override var syncState: Observable<SyncState> {
            return self.syncStateStub.asObservable()
        }

        override var storageState: Observable<LoginStoreState> {
            return self.storageStateStub.asObservable()
        }

        override func get(_ id: String) -> Observable<LoginRecord?> {
            return self.getStub.asObservable()
        }
    }

    class FakeItemListDisplayStore: ItemListDisplayStore {
        var itemListDisplaySubject = PublishSubject<ItemListDisplayAction>()

        override var listDisplay: Observable<ItemListDisplayAction> {
            return self.itemListDisplaySubject.asObservable()
        }
    }

    class FakeUserDefaultStore: UserDefaultStore {
        var itemListSortStub = PublishSubject<Setting.ItemListSort>()

        override var itemListSort: Observable<Setting.ItemListSort> {
            return self.itemListSortStub.asObservable()
        }
    }

    class FakeItemDetailStore: ItemDetailStore {
        var itemDetailIdStub = ReplaySubject<String>.create(bufferSize: 1)

        override var itemDetailId: Observable<String> {
            return self.itemDetailIdStub.asObservable()
        }
    }

    class FakeSizeClassStore: SizeClassStore {
        var shouldDisplaySidebarStub = ReplaySubject<Bool>.create(bufferSize: 1)

        override var shouldDisplaySidebar: Observable<Bool> {
            return self.shouldDisplaySidebarStub.asObservable()
        }
    }

    class FakeNetworkStore: NetworkStore {
        var networkAvailableStub = ReplaySubject<Bool>.create(bufferSize: 1)

        override var connectedToNetwork: Observable<Bool> {
            return self.networkAvailableStub.asObservable()
        }
    }

    private var view: FakeItemListView!
    private var dispatcher: FakeDispatcher!
    private var dataStore: FakeDataStore!
    private var itemListDisplayStore: FakeItemListDisplayStore!
    private var userDefaultStore: FakeUserDefaultStore!
    private var itemDetailStore: FakeItemDetailStore!
    private var sizeClassStore: FakeSizeClassStore!
    private var networkStore: FakeNetworkStore!
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
    var subject: ItemListPresenter!

    override func spec() {
        describe("ItemListPresenter") {
            beforeEach {
                self.view = FakeItemListView()
                self.dispatcher = FakeDispatcher()
                self.dataStore = FakeDataStore(dispatcher: self.dispatcher)
                self.itemListDisplayStore = FakeItemListDisplayStore()
                self.userDefaultStore = FakeUserDefaultStore()
                self.itemDetailStore = FakeItemDetailStore()
                self.sizeClassStore = FakeSizeClassStore()
                self.networkStore = FakeNetworkStore()
                self.view.itemsObserver = self.scheduler.createObserver([ItemSectionModel].self)
                self.view.sortingButtonTitleObserver = self.scheduler.createObserver(String.self)
                self.view.scrollActionObserver = self.scheduler.createObserver(ScrollAction.self)
                self.view.sortButtonEnableObserver = self.scheduler.createObserver(Bool.self)
                self.view.tableViewScrollObserver = self.scheduler.createObserver(Bool.self)
                self.view.dismissSpinnerObserver = self.scheduler.createObserver(Void.self)
                self.view.pullToRefreshObserver = self.scheduler.createObserver(Bool.self)

                self.subject = ItemListPresenter(
                        view: self.view,
                        dispatcher: self.dispatcher,
                        dataStore: self.dataStore,
                        itemListDisplayStore: self.itemListDisplayStore,
                        userDefaultStore: self.userDefaultStore,
                        itemDetailStore: self.itemDetailStore,
                        networkStore: self.networkStore,
                        sizeClassStore: self.sizeClassStore
                )
            }

            describe(".onViewReady()") {
                describe("when the datastore pushes an empty list of items") {
                    beforeEach {
                        self.sizeClassStore.shouldDisplaySidebarStub.onNext(false)
                        self.itemDetailStore.itemDetailIdStub.onNext("1234")
                        self.networkStore.networkAvailableStub.onNext(true)
                        self.subject.onViewReady()
                        self.dataStore.itemListStub.onNext([])
                        self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListFilterAction(filteringText: ""))
                        self.userDefaultStore.itemListSortStub.onNext(Setting.ItemListSort.alphabetically)
                    }

                    describe("when the datastore is still syncing & prepared") {
                        beforeEach {
                            self.dataStore.syncStateStub.onNext(SyncState.Syncing(supressNotification: false))
                            self.itemListDisplayStore.itemListDisplaySubject.onNext(PullToRefreshAction(refreshing: false))
                            self.dataStore.storageStateStub.onNext(LoginStoreState.Unlocked)
                        }

                        it("tells the view to display the spinner") {
                            expect(self.view.displaySpinnerCalled).to(beTrue())
                        }

                        it("pushes the placeholder image to the itemlist") {
                            let expectedItemConfigurations = [
                                LoginListCellConfiguration.SyncListPlaceholder
                            ]
                            expect(self.view.itemsObserver.events.first!.value.element).notTo(beNil())
                            let configuration = self.view.itemsObserver.events.first!.value.element!
                            expect(configuration.first!.items).to(equal(expectedItemConfigurations))
                        }

                        it("disables the sorting button and the tableview") {
                            expect(self.view.sortButtonEnableObserver.events.last!.value.element).to(beFalse())
                            expect(self.view.tableViewScrollObserver.events.last!.value.element).to(beFalse())
                        }

                        describe("once the datastore is synced") {
                            beforeEach {
                                self.dataStore.syncStateStub.onNext(SyncState.Synced)
                                self.itemListDisplayStore.itemListDisplaySubject.onNext(PullToRefreshAction(refreshing: false))
                            }

                            it("dismisses the spinner") {
                                expect(self.view.dismissSpinnerObserver.events.count).to(equal(1))
                            }

                            it("enables the sorting button and the tableviewscroll") {
                                expect(self.view.sortButtonEnableObserver.events.last!.value.element).to(beTrue())
                                expect(self.view.tableViewScrollObserver.events.last!.value.element).to(beTrue())
                            }

                            it("displays the emptylist placeholder") {
                                let fakeObserver = self.scheduler.createObserver(Void.self).asObserver()
                                let expectedItemConfigurations = [
                                    LoginListCellConfiguration.EmptyListPlaceholder(learnMoreObserver: fakeObserver)
                                ]
                            expect(self.view.itemsObserver.events.last!.value.element!.first!.items).to(equal(expectedItemConfigurations))
                            }

                            describe("tapping the learnMore button in the empty list placeholder") {
                                beforeEach {
                                    let fakeObserver = self.scheduler.createObserver(Void.self).asObserver()
                                    let expectedItemConfigurations = [
                                        LoginListCellConfiguration.EmptyListPlaceholder(learnMoreObserver: fakeObserver)
                                    ]
                                    expect(self.view.itemsObserver.events.last!.value.element!.first!.items).to(equal(expectedItemConfigurations))

                                    let configuration = self.view.itemsObserver.events.last!.value.element
                                    let emptyListPlaceholder = configuration!.first!.items[0]
                                    if case let .EmptyListPlaceholder(learnMoreObserver) = emptyListPlaceholder {
                                        learnMoreObserver!.onNext(())
                                    } else {
                                        fail("wrong item configuration!")
                                    }
                                }

                                it("routes to the learn more view") {
                                    let argument = self.dispatcher.dispatchedActions.popLast() as! ExternalWebsiteRouteAction
                                    expect(argument).to(equal(ExternalWebsiteRouteAction(
                                            urlString: Constant.app.enableSyncFAQ,
                                            title: Constant.string.faq,
                                            returnRoute: MainRouteAction.list)))
                                }
                            }
                        }

                        describe("if the sync times out") {
                            beforeEach {
                                self.dataStore.syncStateStub.onNext(SyncState.TimedOut)
                            }

                            it("displays a temporary alert for the user") {
                                expect(self.view.temporaryAlertArgument).to(equal(Constant.string.syncTimedOut))
                            }
                        }
                    }

                    describe("manual sync") {
                        describe("started") {
                            beforeEach {
                                self.itemListDisplayStore.itemListDisplaySubject.onNext(PullToRefreshAction(refreshing: true))
                                self.dataStore.syncStateStub.onNext(SyncState.Syncing(supressNotification: false))
                            }

                            it("tells the view to show pull to refresh") {
                                expect(self.view.pullToRefreshObserver.events.last!.value.element).to(beTrue())
                            }

                            it("does not display the initial load spinner") {
                                expect(self.view.displaySpinnerCalled).to(beFalse())
                            }
                        }

                        describe("finishes") {
                            beforeEach {
                                self.itemListDisplayStore.itemListDisplaySubject.onNext(PullToRefreshAction(refreshing: true))
                                self.dataStore.syncStateStub.onNext(SyncState.Synced)
                            }

                            it("resets the refreshing action") {
                                let action = self.dispatcher.dispatchedActions.popLast() as! PullToRefreshAction
                                expect(action.refreshing).to(beFalse())
                            }

                            it("tells the view to hide pull to refresh") {
                                expect(self.view.pullToRefreshObserver.events.last!.value.element).to(beFalse())
                            }
                        }
                    }
                }

                describe("when the datastore pushes a populated list of items & is prepared") {
                    let webAddress1 = "http://meow"
                    let webAddress2 = "http://aaaaaa"
                    let username = "cats@cats.com"

                    let id1 = "fdsdfsfdsfds"
                    let id2 = "ghfhghgff"
                    let items = [
                        LoginRecord(fromJSONDict: ["id": id1, "hostname": webAddress1, "username": username, "password": ""]),
                        LoginRecord(fromJSONDict: ["id": id2, "hostname": "", "username": "", "password": ""]),
                        LoginRecord(fromJSONDict: ["id": "ff", "hostname": webAddress2, "username": "", "password": "fdsfdsfd"])
                    ]

                    describe("when in wide view with sidebar") {
                        beforeEach {
                            self.itemDetailStore.itemDetailIdStub.onNext("ff")
                            self.networkStore.networkAvailableStub.onNext(true)
                            self.sizeClassStore.shouldDisplaySidebarStub.onNext(true)
                            self.subject.onViewReady()
                            self.dataStore.itemListStub.onNext(items)
                            self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListFilterAction(filteringText: ""))
                            self.userDefaultStore.itemListSortStub.onNext(Setting.ItemListSort.alphabetically)
                            self.dataStore.syncStateStub.onNext(SyncState.Synced)
                            self.dataStore.storageStateStub.onNext(LoginStoreState.Unlocked)
                        }

                        it("highlights the selected item") {
                            let expectedItemConfigurations = [
                                LoginListCellConfiguration.Item(title: "", username: Constant.string.usernamePlaceholder, guid: id2, highlight: false),
                                LoginListCellConfiguration.Item(title: "aaaaaa", username: Constant.string.usernamePlaceholder, guid: "ff", highlight: true),
                                LoginListCellConfiguration.Item(title: "meow", username: username, guid: id1, highlight: false)
                            ]
                            expect(self.view.itemsObserver.events.first!.value.element).notTo(beNil())
                            let configuration = self.view.itemsObserver.events.first!.value.element!
                            expect(configuration.first!.items).to(equal(expectedItemConfigurations))
                        }
                    }

                    describe("when in narrow view") {
                        beforeEach {
                            self.itemDetailStore.itemDetailIdStub.onNext("ff")
                            self.networkStore.networkAvailableStub.onNext(true)
                            self.sizeClassStore.shouldDisplaySidebarStub.onNext(false)
                            self.subject.onViewReady()
                            self.dataStore.itemListStub.onNext(items)
                            self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListFilterAction(filteringText: ""))
                            self.userDefaultStore.itemListSortStub.onNext(Setting.ItemListSort.alphabetically)
                            self.dataStore.syncStateStub.onNext(SyncState.Synced)
                            self.dataStore.storageStateStub.onNext(LoginStoreState.Unlocked)
                        }

                        it("tells the view to display the items in alphabetic order by title") {
                            let expectedItemConfigurations = [
                                LoginListCellConfiguration.Item(title: "", username: Constant.string.usernamePlaceholder, guid: id2, highlight: false),
                                LoginListCellConfiguration.Item(title: "aaaaaa", username: Constant.string.usernamePlaceholder, guid: "ff", highlight: false),
                                LoginListCellConfiguration.Item(title: "meow", username: username, guid: id1, highlight: false)
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
                                        LoginListCellConfiguration.Item(title: "meow", username: username, guid: id1, highlight: false)
                                    ]

                                    expect(self.view.itemsObserver.events.last!.value.element).notTo(beNil())
                                    let configuration = self.view.itemsObserver.events.last!.value.element!
                                    expect(configuration.first!.items).to(equal(expectedItemConfigurations))
                                }
                            }

                            describe("when the text matches an item's origins") {
                                beforeEach {
                                    self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListFilterAction(filteringText: "meow"))
                                }

                                it("updates the view with the appropriate items") {
                                    let expectedItemConfigurations = [
                                        LoginListCellConfiguration.Item(title: "meow", username: username, guid: "", highlight: false)
                                    ]

                                    expect(self.view.itemsObserver.events.last!.value.element).notTo(beNil())
                                    let configuration = self.view.itemsObserver.events.last!.value.element!
                                    expect(configuration.first!.items).to(equal(expectedItemConfigurations))
                                }
                            }

                            describe("when there are no results") {
                                beforeEach {
                                    self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListFilterAction(filteringText: "blahblahblah"))
                                }

                                it("updates the view with the appropriate items") {
                                    let fakeObserver = self.scheduler.createObserver(Void.self).asObserver()
                                    let expectedItemConfigurations = [
                                        LoginListCellConfiguration.NoResults(learnMoreObserver: fakeObserver)
                                    ]

                                    expect(self.view.itemsObserver.events.last!.value.element).notTo(beNil())
                                    let configuration = self.view.itemsObserver.events.last!.value.element!
                                    expect(configuration.first!.items).to(equal(expectedItemConfigurations))
                                }
                            }
                        }
                    }

                    describe("no network") {
                        beforeEach {
                            self.itemDetailStore.itemDetailIdStub.onNext("ff")
                            self.networkStore.networkAvailableStub.onNext(false)
                            self.sizeClassStore.shouldDisplaySidebarStub.onNext(true)
                            self.subject.onViewReady()
                            self.dataStore.itemListStub.onNext(items)
                            self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemListFilterAction(filteringText: ""))
                            self.userDefaultStore.itemListSortStub.onNext(Setting.ItemListSort.alphabetically)
                            self.dataStore.syncStateStub.onNext(SyncState.Synced)
                            self.dataStore.storageStateStub.onNext(LoginStoreState.Unlocked)
                        }

                        it("pushes the no network cell along with the others") {
                            let expectedItemConfigurations = [
                                LoginListCellConfiguration.Item(title: "", username: Constant.string.usernamePlaceholder, guid: id2, highlight: false),
                                LoginListCellConfiguration.Item(title: "aaaaaa", username: Constant.string.usernamePlaceholder, guid: "ff", highlight: true),
                                LoginListCellConfiguration.Item(title: "meow", username: username, guid: id1, highlight: false)
                            ]
                            expect(self.view.itemsObserver.events.first!.value.element).notTo(beNil())
                            let configuration = self.view.itemsObserver.events.first!.value.element!
                            expect(configuration.first!.items.first).to(equal(LoginListCellConfiguration.NoNetwork(retryObserver: self.scheduler.createObserver(Void.self).asObserver())))
                            expect(configuration.first!.items).to(contain(expectedItemConfigurations))
                        }

                        describe("tapping the retry button") {
                            beforeEach {
                                let configuration = self.view.itemsObserver.events.first!.value.element!
                                guard case let .NoNetwork(retryObserver) = configuration.first!.items.first! else {
                                    fail("wrong configuration!")
                                    return
                                }

                                retryObserver.onNext(())
                            }

                            it("dispatches the refresh action") {
                                expect(self.dispatcher.dispatchedActions.popLast() as? NetworkAction).to(equal(NetworkAction.retry))
                            }
                        }
                    }

                    xdescribe("when sorting method switches to recently used") {
                        // pended until it's possible to construct Logins with recently_used dates
                        beforeEach {
                            self.userDefaultStore.itemListSortStub.onNext(Setting.ItemListSort.recentlyUsed)
                        }

                        it("pushes the new configuration with the items") {
                            let expectedItemConfigurations = [
                                LoginListCellConfiguration.Item(title: webAddress1, username: username, guid: id1, highlight: false),
                                LoginListCellConfiguration.Item(title: "", username: Constant.string.usernamePlaceholder, guid: id2, highlight: false),
                                LoginListCellConfiguration.Item(title: webAddress2, username: Constant.string.usernamePlaceholder, guid: "fdssdf", highlight: false)
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
                    let textObservable = self.scheduler.createColdObservable([Recorded.next(40, text)])
                    textObservable.bind(to: self.subject.filterTextObserver).disposed(by: self.disposeBag)
                    self.scheduler.start()
                }

                it("dispatches the filtertext item list display action and editing action") {
                    let editingAction = self.dispatcher.dispatchedActions.popLast() as! ItemListFilterEditAction
                    expect(editingAction.editing).to(beTrue())

                    let filterAction = self.dispatcher.dispatchedActions.popLast() as! ItemListFilterAction
                    expect(filterAction.filteringText).to(equal(text))
                }
            }

            describe("cancelClicked") {
                beforeEach {
                    let cancelObservable = self.scheduler.createColdObservable([Recorded.next(50, ())])
                    cancelObservable.bind(to: self.subject.cancelObserver).disposed(by: self.disposeBag)
                    self.scheduler.start()
                }

                it("dispatches the filtertext item list display action and editing action") {
                    let editingAction = self.dispatcher.dispatchedActions.popLast() as! ItemListFilterEditAction
                    expect(editingAction.editing).to(beFalse())

                    let filterAction = self.dispatcher.dispatchedActions.popLast() as! ItemListFilterAction
                    expect(filterAction.filteringText).to(equal(""))
                }
            }

            describe("itemDeleted") {
                beforeEach {
                    self.subject.onViewReady()
                    self.view.fakeItemDeleted.onNext("asdf")
                }

                it("tells the view to display the confirmation dialog") {
                    expect(self.view.displayOptionSheetTitle).to(equal(Constant.string.confirmDeleteLoginDialogTitle))
                }
            }

            describe("item deleted from store") {
                beforeEach {
                    self.subject.onViewReady()
                    self.itemListDisplayStore.itemListDisplaySubject.onNext(ItemDeletedAction(name: "mozilla.org", id: "1234"))
                }

                it("tells the view to display the toast") {
                    expect(self.view.deletedMessage).to(contain("mozilla.org"))
                }
            }

            describe("itemSelected") {
                describe("when the item has an id") {
                    let id = "fsjksdfjklsdfjlkdsf"

                    beforeEach {
                        let itemObservable = self.scheduler.createColdObservable([
                            Recorded.next(50, id)
                        ])

                        itemObservable
                                .bind(to: self.subject.itemSelectedObserver)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("tells the route action handler to display the detail view for the relevant item") {
                        let argument = self.dispatcher.dispatchedActions.popLast() as! MainRouteAction
                        expect(argument).to(equal(.detail(itemId: id)))
                    }

                    it("dismisses the keyboard") {
                        expect(self.view.dismissKeyboardCalled).to(beTrue())
                    }
                }

                describe("when the item does not have an id") {
                    beforeEach {
                        let itemObservable: TestableObservable<String?> = self.scheduler.createColdObservable([Recorded.next(50, nil)])

                        itemObservable
                                .bind(to: self.subject.itemSelectedObserver)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("does nothing") {
                        expect(self.dispatcher.dispatchedActions).to(beEmpty())
                    }
                }
            }

            describe("sortingButton") {
                beforeEach {
                    self.subject.onViewReady()

                    let itemSettingObservable: TestableObservable<ScrollAction> = self.scheduler.createColdObservable([Recorded.next(50, ScrollAction.toTop)])
                    itemSettingObservable
                        .bind(to: self.view.scrollActionObserver)
                        .disposed(by: self.disposeBag)

                    self.view.fakeOnSortingButtonPressed.onNext(())

                    self.scheduler.start()
                    self.userDefaultStore.itemListSortStub.onNext(Setting.ItemListSort.alphabetically)
                }

                it("tells the view to display an option sheet") {
                    expect(self.view.displayOptionSheetButtons).notTo(beNil())
                    expect(self.view.displayOptionSheetTitle).notTo(beNil())
                    expect(self.view.displayOptionSheetButtons?.first?.checked).to(beTrue())
                    expect(self.view.displayOptionSheetButtons?[1].checked).to(beFalse())

                    expect(self.view.displayOptionSheetTitle).to(equal(Constant.string.sortEntries))
                }

                describe("tapping alphabetically") {
                    beforeEach {
                        self.view.displayOptionSheetButtons![0].tapObserver!.onNext(())
                    }

                    it("dispatches the alphabetically Setting.ItemListSort. SettingAction") {
                        let action = self.dispatcher.dispatchedActions.last as? SettingAction
                        expect(action).notTo(beNil())
                        expect(action).to(equal(SettingAction.itemListSort(sort: Setting.ItemListSort.alphabetically)))
                    }

                    it("dispatches the scroll to top action. ScrollAction") {
                        let dispatched = self.dispatcher.dispatchedActions.dropLast()
                        let action = dispatched.last as? ScrollAction
                        expect(action).notTo(beNil())
                        expect(action).to(equal(ScrollAction.toTop))
                    }

                    it("scrolls to top") {
                        expect(self.view.scrollActionObserver.events.count).to(equal(1))
                        expect(self.view.scrollToTopCalled).to(beTrue())
                    }
                }

                describe("tapping recently used") {
                    beforeEach {
                        self.view.displayOptionSheetButtons![1].tapObserver!.onNext(())
                    }

                    it("dispatches the recently used Setting.ItemListSort. SettingAction") {
                        let action = self.dispatcher.dispatchedActions.last as? SettingAction
                        expect(action).notTo(beNil())
                        expect(action).to(equal(SettingAction.itemListSort(sort: Setting.ItemListSort.recentlyUsed)))
                    }

                    it("dispatches the scroll to top action. ScrollAction") {
                        let dispatched = self.dispatcher.dispatchedActions.dropLast()
                        let action = dispatched.last as? ScrollAction
                        expect(action).notTo(beNil())
                        expect(action).to(equal(ScrollAction.toTop))
                    }

                    it("scrolls to top") {
                        expect(self.view.scrollActionObserver.events.count).to(equal(1))
                        expect(self.view.scrollToTopCalled).to(beTrue())
                    }
                }
            }

            describe("settings button") {
                beforeEach {
                    self.subject.onViewReady()
                    self.view.fakeOnSettingsPressed.onNext(())
                }

                it("dispatches the setting route action") {
                    let action = self.dispatcher.dispatchedActions.popLast() as! SettingRouteAction
                    expect(action).to(equal(.list))
                }
            }

            describe("setFilter with empty list") {
                beforeEach {
                    self.subject.onViewReady()
                    self.dataStore.itemListStub.onNext([])
                }

                it("disables the filter") {
                    expect(self.view.setFilterEnabledValue).to(beFalse())
                }
            }

            describe("setFilter with populated list") {
                beforeEach {
                    self.subject.onViewReady()
                    self.dataStore.itemListStub.onNext([LoginRecord(fromJSONDict: ["id": "asdf", "hostname": "mozilla.com", "username": "asdf", "password": "fdsa"])])
                }

                it("enables the filter") {
                    expect(self.view.setFilterEnabledValue).to(beTrue())
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift
import RxCocoa

@testable import Lockbox

class ItemDetailPresenterSpec: QuickSpec {
    class FakeItemDetailView: ItemDetailViewProtocol {
        fileprivate(set) var itemId: String = "somefakeitemidinhere"
        var titleTextObserver: TestableObserver<String>!
        var itemDetailObserver: TestableObserver<[ItemDetailSectionModel]>!
        var tempAlertMessage: String?
        var tempAlertTimeout: TimeInterval?

        private let disposeBag = DisposeBag()

        func bind(titleText: Driver<String>) {
            titleText
                    .drive(self.titleTextObserver)
                    .disposed(by: self.disposeBag)
        }

        func bind(itemDetail: Driver<[ItemDetailSectionModel]>) {
            itemDetail
                    .drive(self.itemDetailObserver)
                    .disposed(by: self.disposeBag)
        }

        func displayTemporaryAlert(_ message: String, timeout: TimeInterval) {
            self.tempAlertMessage = message
            self.tempAlertTimeout = timeout
        }
    }

    class FakeDataStore: DataStore {
        var onItemStub = PublishSubject<Item>()
        var itemIDArgument: String?

        override func onItem(_ itemId: String) -> Observable<Item> {
            self.itemIDArgument = itemId
            return onItemStub.asObservable()
        }
    }

    class FakeCopyDisplayStore: CopyConfirmationDisplayStore {
        var copyDisplayStub = PublishSubject<CopyConfirmationDisplayAction>()

        override var copyDisplay: Driver<CopyConfirmationDisplayAction> {
            return self.copyDisplayStub.asDriver(onErrorJustReturn: CopyConfirmationDisplayAction(fieldName: ""))
        }
    }

    class FakeItemDetailStore: ItemDetailStore {
        var itemDetailDisplayStub = PublishSubject<ItemDetailDisplayAction>()

        override var itemDetailDisplay: Driver<ItemDetailDisplayAction> {
            return itemDetailDisplayStub.asDriver(onErrorJustReturn: .togglePassword(displayed: false))
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var routeActionArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.routeActionArgument = action
        }
    }

    class FakeCopyActionHandler: CopyActionHandler {
        var invokedAction: CopyAction?

        override func invoke(_ action: CopyAction) {
            self.invokedAction = action
        }
    }

    class FakeItemDetailActionHandler: ItemDetailActionHandler {
        var displayActionArgument: ItemDetailDisplayAction?

        override func invoke(_ displayAction: ItemDetailDisplayAction) {
            self.displayActionArgument = displayAction
        }
    }

    private var view: FakeItemDetailView!
    private var dataStore: FakeDataStore!
    private var copyDisplayStore: FakeCopyDisplayStore!
    private var itemDetailStore: FakeItemDetailStore!
    private var routeActionHandler: FakeRouteActionHandler!
    private var copyActionHandler: FakeCopyActionHandler!
    private var itemDetailActionHandler: FakeItemDetailActionHandler!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: ItemDetailPresenter!

    override func spec() {
        describe("ItemDetailPresenter") {
            beforeEach {
                self.view = FakeItemDetailView()
                self.dataStore = FakeDataStore()
                self.copyDisplayStore = FakeCopyDisplayStore()
                self.itemDetailStore = FakeItemDetailStore()
                self.routeActionHandler = FakeRouteActionHandler()
                self.copyActionHandler = FakeCopyActionHandler()
                self.itemDetailActionHandler = FakeItemDetailActionHandler()

                self.subject = ItemDetailPresenter(
                        view: self.view,
                        dataStore: self.dataStore,
                        itemDetailStore: self.itemDetailStore,
                        copyDisplayStore: self.copyDisplayStore,
                        routeActionHandler: self.routeActionHandler,
                        copyActionHandler: self.copyActionHandler,
                        itemDetailActionHandler: self.itemDetailActionHandler
                )
            }

            it("starts the password display as hidden") {
                expect(self.itemDetailActionHandler.displayActionArgument).notTo(beNil())
                expect(self.itemDetailActionHandler.displayActionArgument)
                        .to(equal(ItemDetailDisplayAction.togglePassword(displayed: false)))
            }

            describe("onPasswordToggle") {
                let passwordRevealSelected = true
                beforeEach {
                    let tapObservable = self.scheduler.createColdObservable([next(50, passwordRevealSelected)])

                    tapObservable
                            .bind(to: self.subject.onPasswordToggle)
                            .disposed(by: self.disposeBag)

                    self.scheduler.start()
                }

                it("dispatches the password action with the value") {
                    expect(self.itemDetailActionHandler.displayActionArgument).notTo(beNil())
                    expect(self.itemDetailActionHandler.displayActionArgument)
                            .to(equal(ItemDetailDisplayAction.togglePassword(displayed: passwordRevealSelected)))
                }
            }

            describe("onCancel") {
                beforeEach {
                    let cancelObservable = self.scheduler.createColdObservable([next(50, ())])

                    cancelObservable
                            .bind(to: self.subject.onCancel)
                            .disposed(by: self.disposeBag)

                    self.scheduler.start()
                }

                it("routes to the item list") {
                    expect(self.routeActionHandler.routeActionArgument).notTo(beNil())
                    let argument = self.routeActionHandler.routeActionArgument as! MainRouteAction
                    expect(argument).to(equal(MainRouteAction.list))
                }
            }

            describe("onCellTapped") {
                describe("when the title of the tapped cell is the username constant") {
                    beforeEach {
                        let cellTappedObservable = self.scheduler.createColdObservable([next(50, Constant.string.username)])

                        cellTappedObservable
                                .bind(to: self.subject.onCellTapped)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("requests the current item from the datastore") {
                        expect(self.dataStore.itemIDArgument).notTo(beNil())
                    }

                    describe("getting the item") {
                        describe("when the item has a username") {
                            let username = "some username"

                            beforeEach {
                                let item = Item.Builder()
                                        .entry(
                                                ItemEntry.Builder()
                                                        .username(username)
                                                        .build())
                                        .build()
                                self.dataStore.onItemStub.onNext(item)
                            }

                            it("dispatches the copy action") {
                                expect(self.copyActionHandler.invokedAction).notTo(beNil())
                                expect(self.copyActionHandler.invokedAction).to(equal(CopyAction(text: username, fieldName: Constant.string.username)))
                            }
                        }

                        describe("when the item does not have a username") {
                            beforeEach {
                                let item = Item.Builder()
                                        .entry(
                                                ItemEntry.Builder()
                                                        .build())
                                        .build()
                                self.dataStore.onItemStub.onNext(item)
                            }

                            it("dispatches the copy action with no text") {
                                expect(self.copyActionHandler.invokedAction).notTo(beNil())
                                expect(self.copyActionHandler.invokedAction).to(equal(CopyAction(text: "", fieldName: Constant.string.username)))
                            }
                        }
                    }
                }

                describe("when the title of the tapped cell is the password constant") {
                    beforeEach {
                        let cellTappedObservable = self.scheduler.createColdObservable([next(50, Constant.string.password)])

                        cellTappedObservable
                                .bind(to: self.subject.onCellTapped)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("requests the current item from the datastore") {
                        expect(self.dataStore.itemIDArgument).notTo(beNil())
                    }

                    describe("getting the item") {
                        describe("when the item has a password") {
                            let password = "some password"

                            beforeEach {
                                let item = Item.Builder()
                                        .entry(
                                                ItemEntry.Builder()
                                                        .password(password)
                                                        .build())
                                        .build()
                                self.dataStore.onItemStub.onNext(item)
                            }

                            it("dispatches the copy action") {
                                expect(self.copyActionHandler.invokedAction).notTo(beNil())
                                expect(self.copyActionHandler.invokedAction).to(equal(CopyAction(text: password, fieldName: Constant.string.password)))
                            }
                        }

                        describe("when the item does not have a password") {
                            beforeEach {
                                let item = Item.Builder()
                                        .entry(
                                                ItemEntry.Builder()
                                                        .build())
                                        .build()
                                self.dataStore.onItemStub.onNext(item)
                            }

                            it("dispatches the copy action with no text") {
                                expect(self.copyActionHandler.invokedAction).notTo(beNil())
                                expect(self.copyActionHandler.invokedAction).to(equal(CopyAction(text: "", fieldName: Constant.string.password)))
                            }
                        }
                    }
                }

                describe("all other cells") {
                    beforeEach {
                        let cellTappedObservable = self.scheduler.createColdObservable([next(50, Constant.string.webAddress)])

                        cellTappedObservable
                                .bind(to: self.subject.onCellTapped)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("does nothing") {
                        expect(self.dataStore.itemIDArgument).to(beNil())
                        expect(self.copyActionHandler.invokedAction).to(beNil())
                    }
                }
            }

            describe(".onViewReady") {
                let item = Item.Builder()
                        .title("some title")
                        .origins(["www.cats.com"])
                        .entry(ItemEntry.Builder()
                                .username("meow")
                                .password("iluvkatz")
                                .notes("long notes string yayayaya")
                                .build())
                        .build()

                beforeEach {
                    self.view.itemDetailObserver = self.scheduler.createObserver([ItemDetailSectionModel].self)
                    self.view.titleTextObserver = self.scheduler.createObserver(String.self)

                    self.subject.onViewReady()
                }

                it("requests the correct item from the datastore") {
                    expect(self.dataStore.itemIDArgument).to(equal(self.view.itemId))
                }

                describe("getting an item with the password displayed") {
                    beforeEach {
                        self.dataStore.onItemStub.onNext(item)
                        self.itemDetailStore.itemDetailDisplayStub
                                .onNext(ItemDetailDisplayAction.togglePassword(displayed: true))
                    }

                    it("displays the title") {
                        expect(self.view.titleTextObserver.events.last!.value.element).to(equal(item.title))
                    }

                    it("passes the configuration with a shown password for the item") {
                        let viewConfig = self.view.itemDetailObserver.events.last!.value.element!

                        let webAddressSection = viewConfig[0].items[0]
                        expect(webAddressSection.title).to(equal(Constant.string.webAddress))
                        expect(webAddressSection.value).to(equal(item.origins.first!))
                        expect(webAddressSection.password).to(beFalse())

                        let usernameSection = viewConfig[1].items[0]
                        expect(usernameSection.title).to(equal(Constant.string.username))
                        expect(usernameSection.value).to(equal(item.entry.username!))
                        expect(usernameSection.password).to(beFalse())

                        let passwordSection = viewConfig[1].items[1]
                        expect(passwordSection.title).to(equal(Constant.string.password))
                        expect(passwordSection.value).to(equal(item.entry.password!))
                        expect(passwordSection.password).to(beTrue())

                        let notesSection = viewConfig[2].items[0]
                        expect(notesSection.title).to(equal(Constant.string.notes))
                        expect(notesSection.value).to(equal(item.entry.notes!))
                        expect(notesSection.password).to(beFalse())
                    }
                }

                describe("getting an item without the password displayed") {
                    beforeEach {
                        self.dataStore.onItemStub.onNext(item)
                        self.itemDetailStore.itemDetailDisplayStub
                                .onNext(ItemDetailDisplayAction.togglePassword(displayed: false))
                    }

                    it("displays the title") {
                        expect(self.view.titleTextObserver.events.last!.value.element).to(equal(item.title))
                    }

                    it("passes the configuration with an obscured password for the item") {
                        let viewConfig = self.view.itemDetailObserver.events.last!.value.element!

                        let webAddressSection = viewConfig[0].items[0]
                        expect(webAddressSection.title).to(equal(Constant.string.webAddress))
                        expect(webAddressSection.value).to(equal(item.origins.first!))
                        expect(webAddressSection.password).to(beFalse())

                        let usernameSection = viewConfig[1].items[0]
                        expect(usernameSection.title).to(equal(Constant.string.username))
                        expect(usernameSection.value).to(equal(item.entry.username!))
                        expect(usernameSection.password).to(beFalse())

                        let passwordSection = viewConfig[1].items[1]
                        expect(passwordSection.title).to(equal(Constant.string.password))
                        expect(passwordSection.value).to(equal("••••••••"))
                        expect(passwordSection.password).to(beTrue())

                        let notesSection = viewConfig[2].items[0]
                        expect(notesSection.title).to(equal(Constant.string.notes))
                        expect(notesSection.value).to(equal(item.entry.notes!))
                        expect(notesSection.password).to(beFalse())
                    }
                }

                describe("when there is no title") {
                    beforeEach {
                        item.title = nil
                        self.dataStore.onItemStub.onNext(item)
                        self.itemDetailStore.itemDetailDisplayStub
                                .onNext(ItemDetailDisplayAction.togglePassword(displayed: true))
                    }

                    it("displays the first origins value") {
                        expect(self.view.titleTextObserver.events.last!.value.element).to(equal(item.origins.first!))
                    }
                }

                describe("when there is no title, origin, username, or notes") {
                    beforeEach {
                        item.title = nil
                        item.origins = []
                        item.entry.password = nil
                        item.entry.username = nil
                        item.entry.notes = nil
                        self.dataStore.onItemStub.onNext(item)
                        self.itemDetailStore.itemDetailDisplayStub
                                .onNext(ItemDetailDisplayAction.togglePassword(displayed: true))
                    }

                    it("displays the unnamed entry placeholder text") {
                        expect(self.view.titleTextObserver.events.last!.value.element)
                                .to(equal(Constant.string.unnamedEntry))
                    }

                    it("passes the configuration with an empty string for the appropriate values") {
                        let viewConfig = self.view.itemDetailObserver.events.last!.value.element!

                        expect(viewConfig.count).to(equal(2))

                        let webAddressSection = viewConfig[0].items[0]
                        expect(webAddressSection.title).to(equal(Constant.string.webAddress))
                        expect(webAddressSection.value).to(equal(""))
                        expect(webAddressSection.password).to(beFalse())

                        let usernameSection = viewConfig[1].items[0]
                        expect(usernameSection.title).to(equal(Constant.string.username))
                        expect(usernameSection.value).to(equal(""))
                        expect(usernameSection.password).to(beFalse())

                        let passwordSection = viewConfig[1].items[1]
                        expect(passwordSection.title).to(equal(Constant.string.password))
                        expect(passwordSection.value).to(equal(""))
                        expect(passwordSection.password).to(beTrue())
                    }
                }

                describe("getting a copy display action") {
                    let fieldName = "schmield"

                    beforeEach {
                        self.copyDisplayStore.copyDisplayStub.onNext(CopyConfirmationDisplayAction(fieldName: fieldName))
                    }

                    it("tells the view to display a temporary alert") {
                        expect(self.view.tempAlertMessage).to(equal(String(format: Constant.string.fieldNameCopied, fieldName)))
                        expect(self.view.tempAlertTimeout).to(equal(Constant.number.displayStatusAlertLength))
                    }
                }
            }
        }
    }
}

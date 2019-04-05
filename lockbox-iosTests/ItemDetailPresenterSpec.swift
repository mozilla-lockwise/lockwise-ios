/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift
import RxCocoa
import Logins

@testable import Lockbox

class ItemDetailPresenterSpec: QuickSpec {
    class FakeItemDetailView: ItemDetailViewProtocol {
        var titleTextObserver: TestableObserver<String>!
        var itemDetailObserver: TestableObserver<[ItemDetailSectionModel]>!
        let learnHowToEditStub = PublishSubject<Void>()
        var tempAlertMessage: String?
        var tempAlertTimeout: TimeInterval?
        var enableBackButtonValue: Bool?

        private let disposeBag = DisposeBag()

        var learnHowToEditTapped: Observable<Void> {
            return self.learnHowToEditStub.asObservable()
        }

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

        func enableBackButton(enabled: Bool) {
            self.enableBackButtonValue = enabled
        }
    }

    class FakeDispatcher: Dispatcher {
        var dispatchActionArgument: Action?

        override func dispatch(action: Action) {
            self.dispatchActionArgument = action
        }
    }

    class FakeDataStore: DataStore {
        var onItemStub: PublishSubject<LoginRecord?>
        var loginIDArg: String?

        init() {
            self.onItemStub = PublishSubject<LoginRecord?>()
            super.init()

            self.disposeBag = DisposeBag()
        }

        override func get(_ id: String) -> Observable<LoginRecord?> {
            self.loginIDArg = id
            return onItemStub.asObservable()
        }
    }

    class FakeCopyDisplayStore: CopyDisplayStore {
        var copyDisplayStub = PublishSubject<CopyField>()

        override var copyDisplay: Driver<CopyField> {
            return self.copyDisplayStub.asDriver(onErrorJustReturn: CopyField.password)
        }
    }

    class FakeItemDetailStore: ItemDetailStore {
        var itemDetailDisplayStub = PublishSubject<ItemDetailDisplayAction>()
        var itemDetailIdStub = ReplaySubject<String>.create(bufferSize: 1)

        override var itemDetailDisplay: Driver<ItemDetailDisplayAction> {
            return itemDetailDisplayStub.asDriver(onErrorJustReturn: .togglePassword(displayed: false))
        }

        override var itemDetailId: Observable<String> {
            return itemDetailIdStub.asObservable()
        }
    }

    class FakeSizeClassStore: SizeClassStore {
        var shouldDisplaySidebarStub = ReplaySubject<Bool>.create(bufferSize: 1)

        override var shouldDisplaySidebar: Observable<Bool> {
            return shouldDisplaySidebarStub.asObservable()
        }
    }

    private var view: FakeItemDetailView!
    private var dispatcher: FakeDispatcher!
    private var dataStore: FakeDataStore!
    private var copyDisplayStore: FakeCopyDisplayStore!
    private var itemDetailStore: FakeItemDetailStore!
    private var sizeClassStore: FakeSizeClassStore!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: ItemDetailPresenter!

    override func spec() {
        describe("ItemDetailPresenter") {
            beforeEach {
                self.view = FakeItemDetailView()
                self.dispatcher = FakeDispatcher()
                self.dataStore = FakeDataStore()
                self.copyDisplayStore = FakeCopyDisplayStore()
                self.itemDetailStore = FakeItemDetailStore()
                self.sizeClassStore = FakeSizeClassStore()

                self.subject = ItemDetailPresenter(
                        view: self.view,
                        dispatcher: self.dispatcher,
                        dataStore: self.dataStore,
                        itemDetailStore: self.itemDetailStore,
                        copyDisplayStore: self.copyDisplayStore,
                        sizeClassStore: self.sizeClassStore
                )
            }

            it("starts the password display as hidden") {
                expect(self.dispatcher.dispatchActionArgument).notTo(beNil())
                let action = self.dispatcher.dispatchActionArgument as! ItemDetailDisplayAction
                expect(action).to(equal(.togglePassword(displayed: false)))
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
                    expect(self.dispatcher.dispatchActionArgument).notTo(beNil())
                    let action = self.dispatcher.dispatchActionArgument as! ItemDetailDisplayAction
                    expect(action).to(equal(.togglePassword(displayed: passwordRevealSelected)))
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
                    expect(self.dispatcher.dispatchActionArgument).notTo(beNil())
                    let argument = self.dispatcher.dispatchActionArgument as! MainRouteAction
                    expect(argument).to(equal(.list))
                }
            }

            describe("onCellTapped") {
                describe("when the title of the tapped cell is the username constant") {
                    beforeEach {
                        self.itemDetailStore.itemDetailIdStub.onNext("fsdfds")
                        let cellTappedObservable = self.scheduler.createColdObservable([next(50, Constant.string.username)])

                        cellTappedObservable
                                .bind(to: self.subject.onCellTapped)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("requests the current item from the datastore") {
                        expect(self.dataStore.loginIDArg).notTo(beNil())
                    }

                    describe("getting the item") {
                        describe("when the item has a username") {
                            let username = "some username"

                            beforeEach {
                                let item = LoginRecord(fromJSONDict: ["id": "fsdfds", "hostname": "www.example.com", "username": username, "password": "meow"])
                                self.dataStore.onItemStub.onNext(item)
                            }

                            it("dispatches the copy action") {
                                expect(self.dispatcher.dispatchActionArgument).notTo(beNil())
                                let action = self.dispatcher.dispatchActionArgument as! CopyAction
                                expect(action).to(equal(CopyAction(text: username, field: .username, itemID: "", actionType: .tap)))
                            }
                        }

                        describe("when the item does not have a username") {
                            beforeEach {
                                let item = LoginRecord(fromJSONDict: ["id": "", "hostname": "", "username": "", "password": ""])
                                self.dataStore.onItemStub.onNext(item)
                            }

                            it("dispatches the copy action with no text") {
                                expect(self.dispatcher.dispatchActionArgument).notTo(beNil())
                                let action = self.dispatcher.dispatchActionArgument as! CopyAction
                                expect(action).to(equal(CopyAction(text: "", field: .username, itemID: "", actionType: .tap)))
                            }
                        }
                    }
                }

                describe("when the title of the tapped cell is the password constant") {
                    beforeEach {
                        self.itemDetailStore.itemDetailIdStub.onNext("fsdfds")
                        let cellTappedObservable = self.scheduler.createColdObservable([next(50, Constant.string.password)])

                        cellTappedObservable
                                .bind(to: self.subject.onCellTapped)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("requests the current item from the datastore") {
                        expect(self.dataStore.loginIDArg).notTo(beNil())
                    }

                    describe("getting the item") {
                        describe("when the item has a password") {
                            let password = "some password"

                            beforeEach {
                                let item = LoginRecord(fromJSONDict: ["id": "sdfdsf", "hostname": "www.example.com", "username": "", "password": password])
                                self.dataStore.onItemStub.onNext(item)
                            }

                            it("dispatches the copy action") {
                                expect(self.dispatcher.dispatchActionArgument).notTo(beNil())
                                let action = self.dispatcher.dispatchActionArgument as! CopyAction
                                expect(action).to(equal(CopyAction(text: password, field: .password, itemID: "", actionType: .tap)))
                            }
                        }

                        describe("when the item does not have a password") {
                            beforeEach {
                                let item = LoginRecord(fromJSONDict: ["id": "", "hostname": "", "username": "", "password": ""])
                                self.dataStore.onItemStub.onNext(item)
                            }

                            it("dispatches the copy action with no text") {
                                expect(self.dispatcher.dispatchActionArgument).notTo(beNil())
                                let action = self.dispatcher.dispatchActionArgument as! CopyAction
                                expect(action).to(equal(CopyAction(text: "", field: .password, itemID: "", actionType: .tap)))
                            }
                        }
                    }
                }

                describe("when the title of the tapped cell is the web address constant") {
                    beforeEach {
                        self.itemDetailStore.itemDetailIdStub.onNext("fsdfds")
                        let cellTappedObservable = self.scheduler.createColdObservable([next(50, Constant.string.webAddress)])

                        cellTappedObservable
                            .bind(to: self.subject.onCellTapped)
                            .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("requests the current item from the datastore") {
                        expect(self.dataStore.loginIDArg).notTo(beNil())
                    }

                    describe("getting the item") {
                        let webAddress = "https://www.mozilla.org"

                        beforeEach {
                            let item = LoginRecord(fromJSONDict: ["id": "sdfdfsfd", "hostname": webAddress, "username": "ffs", "password": "ilikecatz"])

                            self.dataStore.onItemStub.onNext(item)
                        }

                        it("dispatches the externalLink action") {
                            expect(self.dispatcher.dispatchActionArgument).notTo(beNil())
                            let action = self.dispatcher.dispatchActionArgument as! ExternalLinkAction
                            expect(action).to(equal(ExternalLinkAction(baseURLString: webAddress)))
                        }
                    }
                }

                describe("all other cells") {
                    beforeEach {
                        let cellTappedObservable = self.scheduler.createColdObservable([next(50, Constant.string.notes)])

                        cellTappedObservable
                                .bind(to: self.subject.onCellTapped)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("does nothing") {
                        expect(self.dataStore.loginIDArg).to(beNil())
                        expect(self.dispatcher.dispatchActionArgument).notTo(beAnInstanceOf(CopyAction.self))
                    }
                }
            }

            describe(".onViewReady") {
                let item = LoginRecord(fromJSONDict: ["id": "sdfsdfdfs", "hostname": "www.cats.com", "username": "meow", "password": "iluv kats"])

                beforeEach {
                    self.view.itemDetailObserver = self.scheduler.createObserver([ItemDetailSectionModel].self)
                    self.view.titleTextObserver = self.scheduler.createObserver(String.self)

                    self.itemDetailStore.itemDetailIdStub.onNext("1234")
                    self.sizeClassStore.shouldDisplaySidebarStub.onNext(false)
                    self.subject.onViewReady()
                }

                it("requests the correct item from the datastore") {
                    expect(self.dataStore.loginIDArg).to(equal("1234"))
                }

                it("enables back button") {
                    expect(self.view.enableBackButtonValue).to(beTrue())
                }

                describe("getting an item with the password displayed") {
                    beforeEach {
                        self.dataStore.onItemStub.onNext(item)
                        self.itemDetailStore.itemDetailDisplayStub
                                .onNext(ItemDetailDisplayAction.togglePassword(displayed: true))
                    }

                    it("displays the title") {
                        expect(self.view.titleTextObserver.events.last!.value.element).to(equal("cats.com"))
                    }

                    it("passes the configuration with a shown password for the item") {
                        let viewConfig = self.view.itemDetailObserver.events.last!.value.element!

                        let webAddressSection = viewConfig[0].items[0]
                        expect(webAddressSection.title).to(equal(Constant.string.webAddress))
                        expect(webAddressSection.value).to(equal(item.hostname))
                        expect(webAddressSection.accessibilityLabel).to(equal(String(format: Constant.string.websiteCellAccessibilityLabel, item.hostname)))
                        expect(webAddressSection.password).to(beFalse())

                        let usernameSection = viewConfig[1].items[0]
                        expect(usernameSection.title).to(equal(Constant.string.username))
                        expect(usernameSection.value).to(equal(item.username))
                        expect(usernameSection.accessibilityLabel).to(equal(String(format: Constant.string.usernameCellAccessibilityLabel, item.username!)))
                        expect(usernameSection.password).to(beFalse())

                        let passwordSection = viewConfig[1].items[1]
                        expect(passwordSection.title).to(equal(Constant.string.password))
                        expect(passwordSection.value).to(equal(item.password))
                        expect(passwordSection.accessibilityLabel).to(equal(String(format: Constant.string.passwordCellAccessibilityLabel, item.password)))
                        expect(passwordSection.password).to(beTrue())
                    }
                }

                describe("getting an item without the password displayed") {
                    beforeEach {
                        self.dataStore.onItemStub.onNext(item)
                        self.itemDetailStore.itemDetailDisplayStub
                                .onNext(ItemDetailDisplayAction.togglePassword(displayed: false))
                    }

                    it("displays the title") {
                        expect(self.view.titleTextObserver.events.last!.value.element).to(equal("cats.com"))
                    }

                    it("passes the configuration with an obscured password for the item") {
                        let viewConfig = self.view.itemDetailObserver.events.last!.value.element!

                        let webAddressSection = viewConfig[0].items[0]
                        expect(webAddressSection.title).to(equal(Constant.string.webAddress))
                        expect(webAddressSection.value).to(equal(item.hostname))
                        expect(webAddressSection.password).to(beFalse())

                        let usernameSection = viewConfig[1].items[0]
                        expect(usernameSection.title).to(equal(Constant.string.username))
                        expect(usernameSection.value).to(equal(item.username!))
                        expect(usernameSection.password).to(beFalse())

                        let passwordSection = viewConfig[1].items[1]
                        expect(passwordSection.title).to(equal(Constant.string.password))
                        expect(passwordSection.value).to(equal("•••••••••"))
                        expect(passwordSection.password).to(beTrue())
                    }

                    it("open button is displayed for web address") {
                        let viewConfig = self.view.itemDetailObserver.events.last!.value.element!

                        let webAddressSection = viewConfig[0].items[0]
                        let usernameSection = viewConfig[1].items[0]
                        let passwordSection = viewConfig[1].items[1]

                        expect(webAddressSection.showOpenButton).to(beTrue())
                        expect(usernameSection.showOpenButton).to(beFalse())
                        expect(passwordSection.showOpenButton).to(beFalse())
                    }

                    it("copy button is displayed for username and password") {
                        let viewConfig = self.view.itemDetailObserver.events.last!.value.element!

                        let webAddressSection = viewConfig[0].items[0]
                        let usernameSection = viewConfig[1].items[0]
                        let passwordSection = viewConfig[1].items[1]

                        expect(webAddressSection.showCopyButton).to(beFalse())
                        expect(usernameSection.showCopyButton).to(beTrue())
                        expect(passwordSection.showCopyButton).to(beTrue())
                    }
                }

                describe("when there is no title, origin, username, or notes") {
                    beforeEach {
                        let emptyItem = LoginRecord(fromJSONDict: ["id": "", "hostname": "", "username": "", "password": ""])
                        self.dataStore.onItemStub.onNext(emptyItem)
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
                    it("tells the view to display a password temporary alert") {
                        self.copyDisplayStore.copyDisplayStub.onNext(CopyField.password)
                        expect(self.view.tempAlertMessage).to(equal(String(format: Constant.string.fieldNameCopied, Constant.string.password)))
                        expect(self.view.tempAlertTimeout).to(equal(Constant.number.displayStatusAlertLength))
                    }

                    it("tells the view to display a username temporary alert") {
                        self.copyDisplayStore.copyDisplayStub.onNext(CopyField.username)
                        expect(self.view.tempAlertMessage).to(equal(String(format: Constant.string.fieldNameCopied, Constant.string.username)))
                        expect(self.view.tempAlertTimeout).to(equal(Constant.number.displayStatusAlertLength))
                    }
                }

                describe("onLearnHowToEditTapped") {
                    beforeEach {
                        self.view.learnHowToEditStub.onNext(())

                        self.itemDetailStore.itemDetailIdStub.onNext("1234")
                    }

                    it("dispatches the faq link action") {
                        expect(self.dispatcher.dispatchActionArgument).notTo(beNil())
                        let argument = self.dispatcher.dispatchActionArgument as! ExternalWebsiteRouteAction
                        expect(argument).to(equal(
                                        ExternalWebsiteRouteAction(
                                                urlString: Constant.app.editExistingEntriesFAQ,
                                                title: Constant.string.faq,
                                                returnRoute: MainRouteAction.detail(itemId: "1234"))
                                ))
                    }
                }
            }

            describe(".onViewReady for view with sidebar") {
                beforeEach {
                    self.view.itemDetailObserver = self.scheduler.createObserver([ItemDetailSectionModel].self)
                    self.view.titleTextObserver = self.scheduler.createObserver(String.self)

                    self.itemDetailStore.itemDetailIdStub.onNext("1234")
                    self.sizeClassStore.shouldDisplaySidebarStub.onNext(true)
                    self.subject.onViewReady()
                }

                it("does not show back button") {
                    expect(self.view.enableBackButtonValue).to(beFalse())
                }
            }

            describe("dndStarted") {
                beforeEach {
                    self.itemDetailStore.itemDetailIdStub.onNext("1234")
                    self.subject.dndStarted(value: "Username")
                    let item = LoginRecord(fromJSONDict: ["id": "1234", "hostname": "www.example.com", "username": "asdf", "password": "meow"])
                    self.dataStore.onItemStub.onNext(item)
                }

                it("sends copy action") {
                    expect(self.dispatcher.dispatchActionArgument).notTo(beNil())
                    let action = self.dispatcher.dispatchActionArgument as! CopyAction
                    expect(action).to(equal(CopyAction(text: "asdf", field: CopyField.username, itemID: "1234", actionType: CopyActionType.dnd)))
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift
import RxCocoa
import MozillaAppServices

@testable import Lockbox

class ItemDetailPresenterSpec: QuickSpec {
    class FakeItemDetailView: ItemDetailViewProtocol {
        var itemDetailObserverStub: TestableObserver<[ItemDetailSectionModel]>!
        var titleTextObserverStub: TestableObserver<String?>!
        var rightButtonTextObserverStub: TestableObserver<String?>!
        var leftButtonTextObserverStub: TestableObserver<String?>!
        var deleteHiddenObserverStub: TestableObserver<Bool>!
        let editStub = PublishSubject<Void>()
        let cellTappedStub = PublishSubject<String?>()
        let deleteTappedStub = PublishSubject<Void>()
        let rightButtonTappedStub = PublishSubject<Void>()
        let leftButtonTappedStub = PublishSubject<Void>()
        var tempAlertMessage: String?
        var tempAlertTimeout: TimeInterval?
        var enableLargeTitleValue: Bool?
        var enableSwipeValue: Bool?

        var itemDetailObserver: ItemDetailSectionModelObserver {
            return { observable -> Disposable in
                observable.subscribe(self.itemDetailObserverStub)
            }
        }

        func enableSwipeNavigation(enabled: Bool) {
            self.enableSwipeValue = enabled
        }

        func enableLargeTitle(enabled: Bool) {
            self.enableLargeTitleValue = enabled
        }

        var cellTapped: Observable<String?> {
            return self.cellTappedStub.asObservable()
        }

        var deleteTapped: Observable<Void> {
            return self.deleteTappedStub.asObservable()
        }

        var rightBarButtonTapped: Observable<Void> {
            return self.rightButtonTappedStub.asObservable()
        }

        var leftBarButtonTapped: Observable<Void> {
            return self.leftButtonTappedStub.asObservable()
        }

        var titleText: AnyObserver<String?> {
            return self.titleTextObserverStub.asObserver()
        }

        var rightButtonText: AnyObserver<String?> {
            return self.rightButtonTextObserverStub.asObserver()
        }

        var leftButtonText: AnyObserver<String?> {
            return self.leftButtonTextObserverStub.asObserver()
        }

        var deleteHidden: AnyObserver<Bool> {
            return self.deleteHiddenObserverStub.asObserver()
        }

        func displayTemporaryAlert(_ message: String, timeout: TimeInterval) {
            self.tempAlertMessage = message
            self.tempAlertTimeout = timeout
        }
    }

    class FakeDispatcher: Dispatcher {
        var dispatchActionArgument: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchActionArgument.append(action)
        }
    }

    class FakeDataStore: DataStore {
        var onItemStub = PublishSubject<LoginRecord?>()
        var lockedStub = ReplaySubject<Bool>.create(bufferSize: 1)
        var loginIDArg: String?

        init() {
            super.init()
            self.disposeBag = DisposeBag()
        }

        override var locked: Observable<Bool> {
            return lockedStub.asObservable()
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
        var passwordRevealedStub = PublishSubject<Bool>()
        var itemDetailIdStub = ReplaySubject<String>.create(bufferSize: 1)
        var isEditingStub = ReplaySubject<Bool>.create(bufferSize: 1)

        override var passwordRevealed: Observable<Bool> {
            return passwordRevealedStub.asObservable()
        }

        override var isEditing: Observable<Bool> {
            return self.isEditingStub.asObservable()
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
                self.view.itemDetailObserverStub = self.scheduler.createObserver([ItemDetailSectionModel].self)
                self.view.titleTextObserverStub = self.scheduler.createObserver(String?.self)
                self.view.rightButtonTextObserverStub = self.scheduler.createObserver(String?.self)
                self.view.leftButtonTextObserverStub = self.scheduler.createObserver(String?.self)
                self.view.deleteHiddenObserverStub = self.scheduler.createObserver(Bool.self)

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

            describe("when swiping right") {
                beforeEach {
                    let cancelObservable = self.scheduler.createColdObservable([next(50, ())])

                    cancelObservable
                            .bind(to: self.subject.onRightSwipe)
                            .disposed(by: self.disposeBag)

                    self.scheduler.start()
                }

                it("routes to the item list") {
                    expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                    let argument = self.dispatcher.dispatchActionArgument.last as! MainRouteAction
                    expect(argument).to(equal(.list))
                }
            }

            describe(".onViewReady") {
                let item = LoginRecord(fromJSONDict: ["id": "sdfsdfdfs", "hostname": "https://www.cats.com", "username": "meow", "password": "iluv kats"])

                beforeEach {
                    self.itemDetailStore.itemDetailIdStub.onNext("1234")
                    self.itemDetailStore.isEditingStub.onNext(false)
                    self.sizeClassStore.shouldDisplaySidebarStub.onNext(false)
                    self.dataStore.lockedStub.onNext(false)
                    self.subject.onViewReady()
                }

                it("requests the correct item from the datastore") {
                    expect(self.dataStore.loginIDArg).to(equal("1234"))
                }

                describe("copy behavior") {
                    describe("when editing") {
                        beforeEach {
                            self.dataStore.onItemStub.onNext(item)
                            self.itemDetailStore.isEditingStub.onNext(true)
                        }

                        it("username does nothing") {
                            self.view.cellTappedStub.onNext(Constant.string.username)
                            expect(self.dispatcher.dispatchActionArgument).to(beEmpty())
                        }

                        it("password does nothing") {
                            self.view.cellTappedStub.onNext(Constant.string.password)
                            expect(self.dispatcher.dispatchActionArgument).to(beEmpty())
                        }

                        it("webAddress does nothing") {
                            self.view.cellTappedStub.onNext(Constant.string.webAddress)
                            expect(self.dispatcher.dispatchActionArgument).to(beEmpty())
                        }
                    }

                    describe("when the title of the tapped cell is the username constant") {
                        describe("getting the item") {
                            describe("when the item has a username") {
                                let username = "some username"

                                beforeEach {
                                    let item = LoginRecord(fromJSONDict: ["id": "fsdfds", "hostname": "www.example.com", "username": username, "password": "meow"])
                                    self.dataStore.onItemStub.onNext(item)
                                    self.view.cellTappedStub.onNext(Constant.string.username)
                                }

                                it("requests the current item from the datastore") {
                                    expect(self.dataStore.loginIDArg).notTo(beNil())
                                }

                                it("dispatches the copy action") {
                                    expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                                    let action = self.dispatcher.dispatchActionArgument.last as! CopyAction
                                    expect(action).to(equal(CopyAction(text: username, field: .username, itemID: "", actionType: .tap)))
                                }
                            }

                            describe("when the item does not have a username") {
                                beforeEach {
                                    let item = LoginRecord(fromJSONDict: ["id": "", "hostname": "", "username": "", "password": ""])
                                    self.dataStore.onItemStub.onNext(item)
                                    self.view.cellTappedStub.onNext(Constant.string.username)
                                }

                                it("requests the current item from the datastore") {
                                    expect(self.dataStore.loginIDArg).notTo(beNil())
                                }

                                it("dispatches the copy action with no text") {
                                    expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                                    let action = self.dispatcher.dispatchActionArgument.last as! CopyAction
                                    expect(action).to(equal(CopyAction(text: "", field: .username, itemID: "", actionType: .tap)))
                                }
                            }
                        }
                    }

                    describe("when the title of the tapped cell is the password constant") {
                        describe("getting the item") {
                            describe("when the item has a password") {
                                let password = "some password"

                                beforeEach {
                                    let item = LoginRecord(fromJSONDict: ["id": "sdfdsf", "hostname": "www.example.com", "username": "", "password": password])
                                    self.dataStore.onItemStub.onNext(item)
                                    self.view.cellTappedStub.onNext(Constant.string.password)
                                }

                                it("requests the current item from the datastore") {
                                    expect(self.dataStore.loginIDArg).notTo(beNil())
                                }

                                it("dispatches the copy action") {
                                    expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                                    let action = self.dispatcher.dispatchActionArgument.last as! CopyAction
                                    expect(action).to(equal(CopyAction(text: password, field: .password, itemID: "", actionType: .tap)))
                                }
                            }

                            describe("when the item does not have a password") {
                                beforeEach {
                                    let item = LoginRecord(fromJSONDict: ["id": "", "hostname": "", "username": "", "password": ""])
                                    self.dataStore.onItemStub.onNext(item)
                                    self.view.cellTappedStub.onNext(Constant.string.password)
                                }

                                it("requests the current item from the datastore") {
                                    expect(self.dataStore.loginIDArg).notTo(beNil())
                                }

                                it("dispatches the copy action with no text") {
                                    expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                                    let action = self.dispatcher.dispatchActionArgument.last as! CopyAction
                                    expect(action).to(equal(CopyAction(text: "", field: .password, itemID: "", actionType: .tap)))
                                }
                            }
                        }
                    }

                    describe("when the title of the tapped cell is the web address constant") {
                        describe("getting the item") {
                            let webAddress = "https://www.mozilla.org"
                            let item = LoginRecord(fromJSONDict: ["id": "sdfdfsfd", "hostname": webAddress, "username": "ffs", "password": "ilikecatz"])

                            beforeEach {
                                self.dataStore.onItemStub.onNext(item)
                                self.view.cellTappedStub.onNext(Constant.string.webAddress)
                            }

                            it("requests the current item from the datastore") {
                                expect(self.dataStore.loginIDArg).notTo(beNil())
                            }

                            it("dispatches the externalLink action") {
                                expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                                let action = self.dispatcher.dispatchActionArgument.last as! ExternalLinkAction
                                expect(action).to(equal(ExternalLinkAction(baseURLString: webAddress)))
                            }

                            describe("subsequent pushes of the same item") {
                                beforeEach {
                                    self.dataStore.onItemStub.onNext(item)
                                }

                                it("dispatches nothing new") {
                                    expect(self.dispatcher.dispatchActionArgument.count).to(equal(1))
                                }
                            }
                        }
                    }

                    describe("all other cells") {
                        let item = LoginRecord(fromJSONDict: ["id": "sdfdfsfd", "hostname": "www.mozilla.org", "username": "ffs", "password": "ilikecatz"])

                        beforeEach {
                            self.dataStore.onItemStub.onNext(item)
                            self.view.cellTappedStub.onNext(Constant.string.notes)
                        }

                        it("does nothing") {
                            expect(self.dispatcher.dispatchActionArgument).to(beEmpty())
                        }
                    }
                }

                describe("getting an item") {
                    var webAddressTestObserver = self.scheduler.createObserver(String.self)
                    var usernameTestObserver = self.scheduler.createObserver(String?.self)
                    var passwordTestObserver = self.scheduler.createObserver(String.self)

                    beforeEach {
                        webAddressTestObserver = self.scheduler.createObserver(String.self)
                        usernameTestObserver = self.scheduler.createObserver(String?.self)
                        passwordTestObserver = self.scheduler.createObserver(String.self)
                        self.dataStore.onItemStub.onNext(item)
                    }

                    it("displays the title") {
                        expect(self.view.titleTextObserverStub.events.last!.value.element).to(equal("cats.com"))
                    }

                    it("passes the configuration for the item") {
                        let viewConfig = self.view.itemDetailObserverStub.events.last!.value.element!

                        let webAddressSection = viewConfig[0].items[0]
                        expect(webAddressSection.title).to(equal(Constant.string.webAddress))
                        expect(webAddressSection.revealPasswordObserver).to(beNil())
                        webAddressSection.value.drive(webAddressTestObserver).disposed(by: self.disposeBag)
                        expect(webAddressTestObserver.events.first?.value.element).to(equal(item.hostname))

                        let usernameSection = viewConfig[1].items[0]
                        expect(usernameSection.title).to(equal(Constant.string.username))
                        expect(usernameSection.revealPasswordObserver).to(beNil())
                        usernameSection.value.drive(usernameTestObserver).disposed(by: self.disposeBag)
                        expect(usernameTestObserver.events.first?.value.element).to(equal(item.username))

                        let passwordSection = viewConfig[1].items[1]
                        expect(passwordSection.title).to(equal(Constant.string.password))
                        expect(passwordSection.revealPasswordObserver).notTo(beNil())
                        passwordSection.value.drive(passwordTestObserver).disposed(by: self.disposeBag)
                        self.itemDetailStore.passwordRevealedStub
                                .onNext(false)
                        expect(passwordTestObserver.events.first?.value.element).to(equal("•••••••••"))
                    }

                    it("displays the password when the itemdetailstore changes") {
                        let viewConfig = self.view.itemDetailObserverStub.events.last!.value.element!
                        let passwordSection = viewConfig[1].items[1]
                        passwordSection.value.drive(passwordTestObserver).disposed(by: self.disposeBag)

                        self.itemDetailStore.passwordRevealedStub.onNext(true)
                        expect(passwordTestObserver.events.last?.value.element).to(equal(item.password))
                    }

                    it("dispatches the reveal password action on password eye taps") {
                        let viewConfig = self.view.itemDetailObserverStub.events.last!.value.element!
                        let passwordSection = viewConfig[1].items[1]
                        passwordSection.revealPasswordObserver!.onNext(true)

                        expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                        let action = self.dispatcher.dispatchActionArgument.last as! ItemDetailDisplayAction
                        expect(action).to(equal(.togglePassword(displayed: true)))
                    }

                    describe("when editing") {
                        beforeEach {
                            self.itemDetailStore.isEditingStub.onNext(true)
                        }

                        it("open button is not displayed for web address or any other cell") {
                            let webAddressObserver = self.scheduler.createObserver(Bool.self)
                            let usernameObserver = self.scheduler.createObserver(Bool.self)
                            let passwordObserver = self.scheduler.createObserver(Bool.self)
                            let viewConfig = self.view.itemDetailObserverStub.events.last!.value.element!

                            let webAddressSection = viewConfig[0].items[0]
                            let usernameSection = viewConfig[1].items[0]
                            let passwordSection = viewConfig[1].items[1]

                            webAddressSection.openButtonHidden.drive(webAddressObserver).disposed(by: self.disposeBag)
                            expect(webAddressObserver.events.first?.value.element).to(beTrue())
                            usernameSection.openButtonHidden.drive(usernameObserver).disposed(by: self.disposeBag)
                            expect(usernameObserver.events.first?.value.element).to(beTrue())
                            passwordSection.openButtonHidden.drive(passwordObserver).disposed(by: self.disposeBag)
                            expect(passwordObserver.events.first?.value.element).to(beTrue())
                        }

                        it("copy button is not displayed for webaddress, username and password") {
                            let webAddressObserver = self.scheduler.createObserver(Bool.self)
                            let usernameObserver = self.scheduler.createObserver(Bool.self)
                            let passwordObserver = self.scheduler.createObserver(Bool.self)
                            let viewConfig = self.view.itemDetailObserverStub.events.last!.value.element!

                            let webAddressSection = viewConfig[0].items[0]
                            let usernameSection = viewConfig[1].items[0]
                            let passwordSection = viewConfig[1].items[1]

                            webAddressSection.copyButtonHidden.drive(webAddressObserver).disposed(by: self.disposeBag)
                            expect(webAddressObserver.events.first?.value.element).to(beTrue())
                            usernameSection.copyButtonHidden.drive(usernameObserver).disposed(by: self.disposeBag)
                            expect(usernameObserver.events.first?.value.element).to(beTrue())
                            passwordSection.copyButtonHidden.drive(passwordObserver).disposed(by: self.disposeBag)
                            expect(passwordObserver.events.first?.value.element).to(beTrue())
                        }

                        it("enforces editability of all fields") {
                            let webAddressObserver = self.scheduler.createObserver(Bool.self)
                            let usernameObserver = self.scheduler.createObserver(Bool.self)
                            let passwordObserver = self.scheduler.createObserver(Bool.self)
                            let viewConfig = self.view.itemDetailObserverStub.events.last!.value.element!

                            let webAddressSection = viewConfig[0].items[0]
                            let usernameSection = viewConfig[1].items[0]
                            let passwordSection = viewConfig[1].items[1]

                            webAddressSection.textFieldEnabled.drive(webAddressObserver).disposed(by: self.disposeBag)
                            expect(webAddressObserver.events.first?.value.element).to(beTrue())
                            usernameSection.textFieldEnabled.drive(usernameObserver).disposed(by: self.disposeBag)
                            expect(usernameObserver.events.first?.value.element).to(beTrue())
                            passwordSection.textFieldEnabled.drive(passwordObserver).disposed(by: self.disposeBag)
                            expect(passwordObserver.events.first?.value.element).to(beTrue())
                        }
                    }

                    describe("when not editing") {
                        beforeEach {
                            self.itemDetailStore.isEditingStub.onNext(false)
                        }

                        it("open button is displayed for web address and no other cell") {
                            let webAddressObserver = self.scheduler.createObserver(Bool.self)
                            let usernameObserver = self.scheduler.createObserver(Bool.self)
                            let passwordObserver = self.scheduler.createObserver(Bool.self)
                            let viewConfig = self.view.itemDetailObserverStub.events.last!.value.element!

                            let webAddressSection = viewConfig[0].items[0]
                            let usernameSection = viewConfig[1].items[0]
                            let passwordSection = viewConfig[1].items[1]

                            webAddressSection.openButtonHidden.drive(webAddressObserver).disposed(by: self.disposeBag)
                            expect(webAddressObserver.events.first?.value.element).to(beFalse())
                            usernameSection.openButtonHidden.drive(usernameObserver).disposed(by: self.disposeBag)
                            expect(usernameObserver.events.first?.value.element).to(beTrue())
                            passwordSection.openButtonHidden.drive(passwordObserver).disposed(by: self.disposeBag)
                            expect(passwordObserver.events.first?.value.element).to(beTrue())
                        }

                        it("copy button is displayed for username and password only") {
                            let webAddressObserver = self.scheduler.createObserver(Bool.self)
                            let usernameObserver = self.scheduler.createObserver(Bool.self)
                            let passwordObserver = self.scheduler.createObserver(Bool.self)
                            let viewConfig = self.view.itemDetailObserverStub.events.last!.value.element!

                            let webAddressSection = viewConfig[0].items[0]
                            let usernameSection = viewConfig[1].items[0]
                            let passwordSection = viewConfig[1].items[1]

                            webAddressSection.copyButtonHidden.drive(webAddressObserver).disposed(by: self.disposeBag)
                            expect(webAddressObserver.events.first?.value.element).to(beTrue())
                            usernameSection.copyButtonHidden.drive(usernameObserver).disposed(by: self.disposeBag)
                            expect(usernameObserver.events.first?.value.element).to(beFalse())
                            passwordSection.copyButtonHidden.drive(passwordObserver).disposed(by: self.disposeBag)
                            expect(passwordObserver.events.first?.value.element).to(beFalse())
                        }

                        it("enforces editability of all fields") {
                            let webAddressObserver = self.scheduler.createObserver(Bool.self)
                            let usernameObserver = self.scheduler.createObserver(Bool.self)
                            let passwordObserver = self.scheduler.createObserver(Bool.self)
                            let viewConfig = self.view.itemDetailObserverStub.events.last!.value.element!

                            let webAddressSection = viewConfig[0].items[0]
                            let usernameSection = viewConfig[1].items[0]
                            let passwordSection = viewConfig[1].items[1]

                            webAddressSection.textFieldEnabled.drive(webAddressObserver).disposed(by: self.disposeBag)
                            expect(webAddressObserver.events.first?.value.element).to(beFalse())
                            usernameSection.textFieldEnabled.drive(usernameObserver).disposed(by: self.disposeBag)
                            expect(usernameObserver.events.first?.value.element).to(beFalse())
                            passwordSection.textFieldEnabled.drive(passwordObserver).disposed(by: self.disposeBag)
                            expect(passwordObserver.events.first?.value.element).to(beFalse())
                        }
                    }
                }

                describe("when there is no title, origin, username, or notes") {
                    beforeEach {
                        let emptyItem = LoginRecord(fromJSONDict: ["id": "", "hostname": "", "username": "", "password": ""])
                        self.dataStore.onItemStub.onNext(emptyItem)
                        self.itemDetailStore.passwordRevealedStub
                                .onNext(true)
                    }

                    it("displays the unnamed entry placeholder text") {
                        expect(self.view.titleTextObserverStub.events.last!.value.element)
                                .to(equal(Constant.string.unnamedEntry))
                    }

                    it("passes the configuration with an empty string for the appropriate values") {
                        let viewConfig = self.view.itemDetailObserverStub.events.last!.value.element!

                        expect(viewConfig.count).to(equal(2))

                        let webAddressSection = viewConfig[0].items[0]
                        expect(webAddressSection.title).to(equal(Constant.string.webAddress))
//                        expect(webAddressSection.value).to(equal(""))
                        expect(webAddressSection.revealPasswordObserver).to(beNil())

                        let usernameSection = viewConfig[1].items[0]
                        expect(usernameSection.title).to(equal(Constant.string.username))
//                        expect(usernameSection.value).to(equal(""))
                        expect(usernameSection.revealPasswordObserver).to(beNil())

                        let passwordSection = viewConfig[1].items[1]
                        expect(passwordSection.title).to(equal(Constant.string.password))
//                        expect(passwordSection.value).to(equal(""))
                        expect(passwordSection.revealPasswordObserver).notTo(beNil())
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

                describe("leftButtonTapped") {
                    describe("when editing") {
                        beforeEach {
                            self.itemDetailStore.isEditingStub.onNext(true)
                            self.view.leftButtonTappedStub.onNext(())
                        }

                        it("dispatches the view mode action") {
                            expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                            expect(self.dispatcher.dispatchActionArgument.popLast() as! ItemDetailDisplayAction)
                                    .to(equal(ItemDetailDisplayAction.viewMode))
                        }
                    }

                    describe("when not editing") {
                        beforeEach {
                            self.itemDetailStore.isEditingStub.onNext(false)
                            self.view.leftButtonTappedStub.onNext(())
                        }

                        it("dispatches the edit mode action") {
                            expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                            expect(self.dispatcher.dispatchActionArgument.popLast() as! MainRouteAction)
                                    .to(equal(MainRouteAction.list))
                        }
                    }
                }

                describe("rightButtonTapped") {
                    describe("when editing") {
                        beforeEach {
                            self.itemDetailStore.isEditingStub.onNext(true)
                            self.view.rightButtonTappedStub.onNext(())
                        }

                        it("dispatches the view mode action") {
                            expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                            expect(self.dispatcher.dispatchActionArgument.popLast() as! ItemDetailDisplayAction)
                                    .to(equal(ItemDetailDisplayAction.viewMode))
                        }
                    }

                    describe("when not editing") {
                        beforeEach {
                            self.itemDetailStore.isEditingStub.onNext(false)
                            self.view.rightButtonTappedStub.onNext(())
                        }

                        it("dispatches the edit mode action") {
                            expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                            expect(self.dispatcher.dispatchActionArgument.popLast() as! ItemDetailDisplayAction)
                                    .to(equal(ItemDetailDisplayAction.editMode))
                        }
                    }
                }

                describe("left button title") {
                    describe("when the sidebar is displayed") {
                        beforeEach {
                            self.sizeClassStore.shouldDisplaySidebarStub.onNext(true)
                        }

                        describe("when editing") {
                            beforeEach {
                                self.itemDetailStore.isEditingStub.onNext(true)
                            }

                            it("pushes cancel") {
                                expect(self.view.leftButtonTextObserverStub.events.last?.value.element).to(equal(Constant.string.cancel))
                            }
                        }

                        describe("when not editing") {
                            beforeEach {
                                self.itemDetailStore.isEditingStub.onNext(false)
                            }

                            it("pushes nil") {
                                expect(self.view.leftButtonTextObserverStub.events.last!.value.element!).to(beNil())
                            }
                        }
                    }

                    describe("when the sidebar is not displayed") {
                        beforeEach {
                            self.sizeClassStore.shouldDisplaySidebarStub.onNext(false)
                        }

                        describe("when editing") {
                            beforeEach {
                                self.itemDetailStore.isEditingStub.onNext(true)
                            }

                            it("pushes cancel") {
                                expect(self.view.leftButtonTextObserverStub.events.last!.value.element).to(equal(Constant.string.cancel))
                            }
                        }

                        describe("when not editing") {
                            beforeEach {
                                self.itemDetailStore.isEditingStub.onNext(false)
                            }

                            it("pushes back") {
                                expect(self.view.leftButtonTextObserverStub.events.last!.value.element).to(equal(Constant.string.back))
                            }
                        }
                    }
                }

                describe("other editing side effects") {
                    describe("when editing") {
                        beforeEach {
                            self.itemDetailStore.isEditingStub.onNext(true)
                        }

                        it("changes the title size, the delete status, and the right button title") {
                            expect(self.view.enableLargeTitleValue).to(beFalse())
                            expect(self.view.deleteHiddenObserverStub.events.last?.value.element).to(equal(false))
                            expect(self.view.rightButtonTextObserverStub.events.last?.value.element).to(equal(Constant.string.save))
                        }
                    }

                    describe("when not editing") {
                        beforeEach {
                            self.itemDetailStore.isEditingStub.onNext(false)
                        }

                        it("changes the title size, the delete status, and the right button title") {
                            expect(self.view.enableLargeTitleValue).to(beTrue())
                            expect(self.view.deleteHiddenObserverStub.events.last?.value.element).to(equal(true))
                            expect(self.view.rightButtonTextObserverStub.events.last?.value.element).to(equal(Constant.string.edit))
                        }
                    }
                }

                describe("sizeClass") {
                    describe("when displaying sidebar") {
                        beforeEach {
                            self.sizeClassStore.shouldDisplaySidebarStub.onNext(true)
                        }
                        
                        it("enables swipe navigation") {
                            expect(self.view.enableSwipeValue).to(beFalse())
                        }
                    }
                    
                    describe("when not displaying sidebar") {
                        beforeEach {
                            self.sizeClassStore.shouldDisplaySidebarStub.onNext(false)
                        }

                        it("disables swipe navigation") {
                            expect(self.view.enableSwipeValue).to(beTrue())
                        }
                    }
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
                    expect(self.dispatcher.dispatchActionArgument).notTo(beEmpty())
                    let action = self.dispatcher.dispatchActionArgument.last as! CopyAction
                    expect(action).to(equal(CopyAction(text: "asdf", field: CopyField.username, itemID: "1234", actionType: CopyActionType.dnd)))
                }
            }
        }
    }
}

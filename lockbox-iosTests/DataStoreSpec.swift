/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import WebKit
import RxTest
import RxSwift

@testable import lockbox_ios

class DataStoreSpec: QuickSpec {
    class FakeWebView: WKWebView, TypedJavaScriptWebView {
        var evaluateJSToBoolCalled: Bool = false
        var evaluateJSCalled: Bool = false

        var evaluateJSArgument = ""

        var loadFileUrlArgument = URL(string: "")
        var loadFileBaseUrlArgument = URL(string: "")

        var firstBoolSingle: Single<Bool>?
        var secondBoolSingle: Single<Bool>?
        var anySingle: Single<Any> = Single.just(false)

        private var boolCallCount = 0

        func evaluateJavaScriptToBool(_ javaScriptString: String) -> Single<Bool> {
            evaluateJSToBoolCalled = true
            evaluateJSArgument = javaScriptString

            boolCallCount += 1
            return boolCallCount == 1 ? firstBoolSingle! : secondBoolSingle!
        }

        func evaluateJavaScript(_ javaScriptString: String) -> Single<Any> {
            evaluateJSCalled = true
            evaluateJSArgument = javaScriptString

            return anySingle
        }

        override func loadFileURL(_ URL: URL, allowingReadAccessTo readAccessURL: URL) -> WKNavigation? {
            loadFileUrlArgument = URL
            loadFileBaseUrlArgument = readAccessURL

            return nil
        }
    }

    class FakeWKNavigation: WKNavigation {
        private var somethingToHoldOnTo:Bool
        override init() {
            somethingToHoldOnTo = true
        }
    }

    class FakeParser: ItemParser {
        var itemFromDictionaryShouldThrow = false
        var jsonStringFromItemShouldThrow = false
        var item:Item!
        var jsonString:String!

        func itemFromDictionary(_ dictionary:[String:Any]) throws -> Item {
            if itemFromDictionaryShouldThrow {
                throw ParserError.InvalidDictionary
            } else {
                return item
            }
        }

        func jsonStringFromItem(_ item:Item) throws -> String {
            if jsonStringFromItemShouldThrow {
                throw ParserError.InvalidItem
            } else {
                return jsonString
            }
        }
    }

    class FakeWKScriptMessage: WKScriptMessage {
        private var providedBody:Any
        private var providedName:String
        override var name:String { get { return providedName } }
        override var body:Any { get { return providedBody } }

        init(name:String, body:Any) {
            self.providedName = name
            self.providedBody = body
        }
    }
    
    var subject: DataStore!
    var webView: FakeWebView!
    var parser:FakeParser!
    private let dataStoreName: String = "dstore"
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()

    override func spec() {
        describe("DataStore") {

            beforeEach {
                self.webView = FakeWebView()
                self.parser = FakeParser()
                var webView = WebView(frame: .zero, configuration: WKWebViewConfiguration())
                self.subject = DataStore(webView: &webView, dataStoreName: self.dataStoreName, parser:self.parser)

                self.subject.webView = self.webView
            }

            xdescribe(".webView(_:didFinish:") {
                // pended because of weird crash when deallocating wknavigation
                it("evaluates open() on the webview datastore") {
                    let fakeNav = FakeWKNavigation()
                    self.webView.navigationDelegate!.webView!(self.webView, didFinish: fakeNav)
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("var \(self.dataStoreName);DataStoreModule.open().then((function (datastore) {\(self.dataStoreName) = datastore;}));"))
                }
            }

            describe(".open()") {
                var openObserver = self.scheduler.createObserver(Any.self)

                beforeEach {
                    openObserver = self.scheduler.createObserver(Any.self)
                    self.webView.anySingle = self.scheduler.createHotObservable([next(100, "some string")])
                            .take(1)
                            .asSingle()
                    self.subject.open()
                            .asObservable()
                            .subscribe(openObserver)
                            .disposed(by: self.disposeBag)
                    self.scheduler.start()
                }

                it("evaluates open() on the webview datastore") {
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("var \(self.dataStoreName);swiftOpen().then(function (datastore) {\(self.dataStoreName) = datastore;});"))
                }

                describe("getting an opencomplete callback from javascript") {
                    let body = "done"
                    
                    beforeEach {
                        let message = FakeWKScriptMessage(name: JSCallbackFunction.OpenComplete.rawValue, body: body)
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    it("pushes the value to the observer") {
                        let value = openObserver.events.first!.value.element as! String
                        expect(value).to(equal(body))
                        expect(openObserver.events.first!.value.error).to(beNil())
                    }
                }

                describe("getting an unknown callback from javascript") {
                    beforeEach {
                        let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    it("pushes the UnexpectedJavaScriptMethod to the observer") {
                        expect(openObserver.events.first!.value.element).to(beNil())
                        expect(openObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedJavaScriptMethod))
                    }
                }
            }

            describe(".initalized()") {
                var boolObserver = self.scheduler.createObserver(Bool.self)

                beforeEach {
                    boolObserver = self.scheduler.createObserver(Bool.self)
                    self.webView.firstBoolSingle = self.scheduler.createHotObservable([next(100, true)])
                            .take(1)
                            .asSingle()
                    self.subject.initialized()
                            .asObservable()
                            .subscribe(boolObserver)
                            .disposed(by: self.disposeBag)
                    self.scheduler.start()
                }

                it("evaluates a bool from .initialized on the webview") {
                    expect(self.webView.evaluateJSToBoolCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).initialized"))
                }

                it("pushes the value from the webview to the returned single") {
                    expect(boolObserver.events.first!.value.element).to(beTrue())
                }
            }

            describe(".initialize(scopedKey:)") {
                var initializeObserver = self.scheduler.createObserver(Any.self)
                let scopedKey = "someLongJWKStringWithQuote"

                beforeEach {
                    initializeObserver = self.scheduler.createObserver(Any.self)

                    self.webView.anySingle = self.scheduler.createHotObservable([next(100, true)])
                            .take(1)
                            .asSingle()
                    self.subject.initialize(scopedKey: scopedKey)
                            .asObservable()
                            .subscribe(initializeObserver)
                            .disposed(by: self.disposeBag)
                    self.scheduler.start()
                }

                it("evaluates javascript to initialize the webview datastore") {
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).initialize({\"appKey\":\(scopedKey)})"))
                }

                describe("getting an initializecomplete callback from javascript") {
                    let body = "done"

                    beforeEach {
                        let message = FakeWKScriptMessage(name: JSCallbackFunction.InitializeComplete.rawValue, body: body)
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    it("pushes the value to the observer") {
                        let value = initializeObserver.events.first!.value.element as! String
                        expect(value).to(equal(body))
                        expect(initializeObserver.events.first!.value.error).to(beNil())
                    }
                }

                describe("getting an unknown callback from javascript") {
                    beforeEach {
                        let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    it("pushes the UnexpectedJavaScriptMethod to the observer") {
                        expect(initializeObserver.events.first!.value.element).to(beNil())
                        expect(initializeObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedJavaScriptMethod))
                    }
                }
            }

            describe(".locked()") {
                var boolObserver = self.scheduler.createObserver(Bool.self)
                beforeEach {
                    boolObserver = self.scheduler.createObserver(Bool.self)
                    self.webView.firstBoolSingle = self.scheduler.createHotObservable([next(100, false)])
                            .take(1)
                            .asSingle()
                    self.subject.locked()
                            .asObservable()
                            .subscribe(boolObserver)
                            .disposed(by: self.disposeBag)
                    self.scheduler.start()
                }

                it("evaluates javascript to query the lock status of the webview datastore") {
                    expect(self.webView.evaluateJSToBoolCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).locked"))
                }

                it("pushes the value from the webview to the returned single") {
                    expect(boolObserver.events.first!.value.element).to(beFalse())
                    expect(boolObserver.events.first!.value.error).to(beNil())
                }
            }

            describe(".unlock(scopedKey:)") {
                var unlockObserver = self.scheduler.createObserver(Any.self)
                let scopedKey = "{\"kty\":\"oct\",\"kid\":\"L9-eBkDrYHdPdXV_ymuzy_u9n3drkQcSw5pskrNl4pg\",\"k\":\"WsTdZ2tjji2W36JN9vk9s2AYsvp8eYy1pBbKPgcSLL4\"}"

                beforeEach {
                    unlockObserver = self.scheduler.createObserver(Any.self)

                    self.webView.anySingle = self.scheduler.createHotObservable([next(100, true)])
                            .take(1)
                            .asSingle()
                    self.subject.unlock(scopedKey: scopedKey)
                            .asObservable()
                            .subscribe(unlockObserver)
                            .disposed(by: self.disposeBag)
                    self.scheduler.start()
                }

                it("evaluates .unlock on the webview datastore") {
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).unlock(\(scopedKey))"))
                }

                describe("getting an unlockcomplete callback from javascript") {
                    let body = "done"

                    beforeEach {
                        let message = FakeWKScriptMessage(name: JSCallbackFunction.UnlockComplete.rawValue, body: body)
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    it("pushes the value to the observer") {
                        let value = unlockObserver.events.first!.value.element as! String
                        expect(value).to(equal(body))
                        expect(unlockObserver.events.first!.value.error).to(beNil())
                    }
                }

                describe("getting an unknown callback from javascript") {
                    beforeEach {
                        let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    it("pushes the UnexpectedJavaScriptMethod to the observer") {
                        expect(unlockObserver.events.first!.value.element).to(beNil())
                        expect(unlockObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedJavaScriptMethod))
                    }
                }
            }

            describe(".lock()") {
                var lockObserver = self.scheduler.createObserver(Any.self)
                beforeEach {
                    lockObserver = self.scheduler.createObserver(Any.self)

                    self.webView.anySingle = self.scheduler.createHotObservable([next(100, true)])
                            .take(1)
                            .asSingle()
                    self.subject.lock()
                            .asObservable()
                            .subscribe(lockObserver)
                            .disposed(by: self.disposeBag)
                    self.scheduler.start()
                }

                it("evaluates .lock on the webview datastore") {
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).lock()"))
                }

                describe("getting a lockcomplete callback from javascript") {
                    let body = "done"

                    beforeEach {
                        let message = FakeWKScriptMessage(name: JSCallbackFunction.LockComplete.rawValue, body: body)
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    it("pushes the value to the observer") {
                        let value = lockObserver.events.first!.value.element as! String
                        expect(value).to(equal(body))
                        expect(lockObserver.events.first!.value.error).to(beNil())
                    }
                }

                describe("getting an unknown callback from javascript") {
                    beforeEach {
                        let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    it("pushes the UnexpectedJavaScriptMethod to the observer") {
                        expect(lockObserver.events.first!.value.element).to(beNil())
                        expect(lockObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedJavaScriptMethod))
                    }
                }
            }

            describe(".list()") {
                var listObserver = self.scheduler.createObserver([Item].self)

                beforeEach {
                    listObserver = self.scheduler.createObserver([Item].self)
                }

                describe("when the datastore is not initialized") {
                    beforeEach {
                        self.webView.firstBoolSingle = self.scheduler.createHotObservable([next(100, false)])
                                .take(1)
                                .asSingle()
                        self.subject.list()
                                .asObservable()
                                .subscribe(listObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("pushes the DataStoreNotInitialized error and no value") {
                        expect(listObserver.events.first!.value.element).to(beNil())
                        expect(listObserver.events.first!.value.error).to(matchError(DataStoreError.NotInitialized))
                    }
                }

                describe("when the datastore is initialized but locked") {
                    beforeEach {
                        self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                .take(1)
                                .asSingle()
                        self.webView.secondBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                .take(1)
                                .asSingle()
                        self.subject.list()
                                .asObservable()
                                .subscribe(listObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("pushes the DataStoreLocked error and no value") {
                        expect(listObserver.events.first!.value.element).to(beNil())
                        expect(listObserver.events.first!.value.error).to(matchError(DataStoreError.Locked))
                    }
                }

                describe("when the datastore is initialized & unlocked") {
                    beforeEach {
                        self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                .take(1)
                                .asSingle()
                        self.webView.secondBoolSingle = self.scheduler.createColdObservable([next(100, false)])
                                .take(1)
                                .asSingle()

                        self.webView.anySingle = self.scheduler.createColdObservable([next(200, "initial success")])
                                .take(1)
                                .asSingle()

                        self.subject.list()
                                .asObservable()
                                .subscribe(listObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("evaluates .list() on the webview datastore") {
                        expect(self.webView.evaluateJSCalled).to(beTrue())
                        expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).list()"))
                    }

                    describe("getting an unknown callback from javascript") {
                        beforeEach {
                            let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                            self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                        }

                        it("pushes the UnexpectedJavaScriptMethod to the observer") {
                            expect(listObserver.events.first!.value.element).to(beNil())
                            expect(listObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedJavaScriptMethod))
                        }
                    }

                    describe("when the webview calls back with a list that does not contain dictionaries") {
                        beforeEach {
                            let message = FakeWKScriptMessage(name: JSCallbackFunction.ListComplete.rawValue, body: [1,2,3])
                            self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                        }

                        it("pushes the UnexpectedType error") {
                            expect(listObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedType))
                            expect(listObserver.events.first!.value.element).to(beNil())
                        }
                    }

                    describe("when the webview calls back with a list that contains only dictionaries") {
                        describe("when the parser is unable to parse items from the dictionary") {
                            beforeEach() {
                                self.parser.itemFromDictionaryShouldThrow = true
                                let message = FakeWKScriptMessage(name: JSCallbackFunction.ListComplete.rawValue, body: [["idvalue",["foo":5,"bar":1]],["idvalue1",["foo":3,"bar":7]]])

                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the InvalidDictionary error") {
                                expect(listObserver.events.first!.value.error).to(matchError(ParserError.InvalidDictionary))
                                expect(listObserver.events.first!.value.element).to(beNil())
                            }
                        }

                        describe("when the parser is able to parse items from the dictionary") {
                            beforeEach() {
                                self.parser.itemFromDictionaryShouldThrow = false
                                self.parser.item = Item.Builder()
                                        .origins(["www.blah.com"])
                                        .id("kdkjdsfsdf")
                                        .entry(ItemEntry.Builder().kind("login").build())
                                        .build()

                                let message = FakeWKScriptMessage(name: JSCallbackFunction.ListComplete.rawValue, body: [["idvalue",["foo":5,"bar":1]],["idvalue1",["foo":3,"bar":7]]])
                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the items") {
                                expect(listObserver.events.first!.value.error).to(beNil())
                                expect(listObserver.events.first!.value.element).to(equal([self.parser.item, self.parser.item]))
                            }
                        }
                    }
                }
            }

            describe(".getItem(item:)") {
                let id = "dfslkjdfslkjsdf"
                var getObserver = self.scheduler.createObserver(Item.self)

                beforeEach {
                    getObserver = self.scheduler.createObserver(Item.self)
                }

                describe("when the datastore is not initialized") {
                    beforeEach {
                        self.webView.firstBoolSingle = self.scheduler.createHotObservable([next(100, false)])
                                .take(1)
                                .asSingle()
                        self.subject.getItem(id)
                                .asObservable()
                                .subscribe(getObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("pushes the DataStoreNotInitialized error and no value") {
                        expect(getObserver.events.first!.value.element).to(beNil())
                        expect(getObserver.events.first!.value.error).to(matchError(DataStoreError.NotInitialized))
                    }
                }

                describe("when the datastore is initialized but locked") {
                    beforeEach {
                        self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                .take(1)
                                .asSingle()
                        self.webView.secondBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                .take(1)
                                .asSingle()
                        self.subject.getItem(id)
                                .asObservable()
                                .subscribe(getObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("pushes the DataStoreLocked error and no value") {
                        expect(getObserver.events.first!.value.element).to(beNil())
                        expect(getObserver.events.first!.value.error).to(matchError(DataStoreError.Locked))
                    }
                }

                describe("when the datastore is initialized & unlocked") {
                    beforeEach {
                        self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                .take(1)
                                .asSingle()
                        self.webView.secondBoolSingle = self.scheduler.createColdObservable([next(100, false)])
                                .take(1)
                                .asSingle()

                        self.webView.anySingle = self.scheduler.createColdObservable([next(100, "standard success")])
                                .take(1)
                                .asSingle()

                        self.subject.getItem(id)
                                .asObservable()
                                .subscribe(getObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("evaluates .get() on the webview datastore") {
                        expect(self.webView.evaluateJSCalled).to(beTrue())
                        expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).get(\"\(id)\")"))
                    }

                    describe("getting an unknown callback from javascript") {
                        beforeEach {
                            let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                            self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                        }

                        it("pushes the UnexpectedJavaScriptMethod to the observer") {
                            expect(getObserver.events.first!.value.element).to(beNil())
                            expect(getObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedJavaScriptMethod))
                        }
                    }

                    describe("when the webview calls back with a non-dictionary") {
                        beforeEach {
                            let message = FakeWKScriptMessage(name: JSCallbackFunction.GetComplete.rawValue, body: [["foo":5],["bar":1]])
                            self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                        }

                        it("pushes the UnexpectedType error") {
                            expect(getObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedType))
                            expect(getObserver.events.first!.value.element).to(beNil())
                        }
                    }

                    describe("when the webview calls back with a dictionary") {
                        let message = FakeWKScriptMessage(name: JSCallbackFunction.GetComplete.rawValue, body: ["foo":5])

                        describe("when the parser is unable to parse items from the dictionary") {
                            beforeEach() {
                                self.parser.itemFromDictionaryShouldThrow = true
                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the InvalidDictionary error") {
                                expect(getObserver.events.first!.value.error).to(matchError(ParserError.InvalidDictionary))
                                expect(getObserver.events.first!.value.element).to(beNil())
                            }
                        }

                        describe("when the parser is able to parse items from the dictionary") {
                            beforeEach() {
                                self.parser.itemFromDictionaryShouldThrow = false
                                self.parser.item = Item.Builder()
                                        .origins(["www.blah.com"])
                                        .id("kdkjdsfsdf")
                                        .entry(ItemEntry.Builder().kind("login").build())
                                        .build()
                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the item") {
                                expect(getObserver.events.first!.value.error).to(beNil())
                                expect(getObserver.events.first!.value.element).to(equal(self.parser.item))
                            }
                        }
                    }
                }
            }

            describe(".addItem(item:)") {
                let itemBuilder = Item.Builder()
                        .origins(["www.barf.com"])
                        .entry(ItemEntry.Builder().kind("fart").build())
                var addObserver = self.scheduler.createObserver(Item.self)
                beforeEach {
                    addObserver = self.scheduler.createObserver(Item.self)
                }

                describe("when the parser is not able to form a json string from the item") {
                    beforeEach {
                        self.parser.jsonStringFromItemShouldThrow = true
                        self.subject.addItem(itemBuilder.build())
                                .asObservable()
                                .subscribe(addObserver)
                                .disposed(by: self.disposeBag)
                    }

                    it("pushes the InvalidItem error") {
                        expect(addObserver.events.first!.value.error).to(matchError(ParserError.InvalidItem))
                        expect(addObserver.events.first!.value.element).to(beNil())
                    }
                }

                describe("when the parser is able to form a json string from the item") {
                    let jsonString = "{ILOOKLIKJSONMAYBE:NOPE}"
                    beforeEach {
                        self.parser.jsonStringFromItemShouldThrow = false
                        self.parser.jsonString = jsonString
                    }
                    
                    describe("when the datastore is not initialized") {
                        beforeEach {
                            self.webView.firstBoolSingle = self.scheduler.createHotObservable([next(100, false)])
                                    .take(1)
                                    .asSingle()
                            self.subject.addItem(itemBuilder.build())
                                    .asObservable()
                                    .subscribe(addObserver)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("pushes the DataStoreNotInitialized error and no value") {
                            expect(addObserver.events.first!.value.element).to(beNil())
                            expect(addObserver.events.first!.value.error).to(matchError(DataStoreError.NotInitialized))
                        }
                    }

                    describe("when the datastore is initialized but locked") {
                        beforeEach {
                            self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                    .take(1)
                                    .asSingle()
                            self.webView.secondBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                    .take(1)
                                    .asSingle()
                            self.subject.addItem(itemBuilder.build())
                                    .asObservable()
                                    .subscribe(addObserver)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("pushes the DataStoreLocked error and no value") {
                            expect(addObserver.events.first!.value.element).to(beNil())
                            expect(addObserver.events.first!.value.error).to(matchError(DataStoreError.Locked))
                        }
                    }

                    describe("when the datastore is initialized & unlocked") {
                        beforeEach {
                            self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                    .take(1)
                                    .asSingle()
                            self.webView.secondBoolSingle = self.scheduler.createColdObservable([next(100, false)])
                                    .take(1)
                                    .asSingle()
                            self.webView.anySingle = self.scheduler.createColdObservable([next(100, "standard success")])
                                    .take(1)
                                    .asSingle()
                            
                            self.subject.addItem(itemBuilder.build())
                                    .asObservable()
                                    .subscribe(addObserver)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("evaluates .add() on the webview datastore with the correctly-JSONified item when given an item without an ID") {
                            expect(self.webView.evaluateJSCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).add(\(jsonString))"))
                        }

                        describe("getting an unknown callback from javascript") {
                            beforeEach {
                                let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the UnexpectedJavaScriptMethod to the observer") {
                                expect(addObserver.events.first!.value.element).to(beNil())
                                expect(addObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedJavaScriptMethod))
                            }
                        }

                        describe("when the webview calls back with a non-dictionary") {
                            beforeEach {
                                let message = FakeWKScriptMessage(name: JSCallbackFunction.AddComplete.rawValue, body: [["foo":5],["bar":1]])
                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the UnexpectedType error") {
                                expect(addObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedType))
                                expect(addObserver.events.first!.value.element).to(beNil())
                            }
                        }

                        describe("when the webview calls back with a dictionary") {
                            let message = FakeWKScriptMessage(name: JSCallbackFunction.AddComplete.rawValue, body: ["foo":5])

                            describe("when the parser is unable to parse items from the dictionary") {
                                beforeEach() {
                                    self.parser.itemFromDictionaryShouldThrow = true
                                    self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                                }

                                it("pushes the InvalidDictionary error") {
                                    expect(addObserver.events.first!.value.error).to(matchError(ParserError.InvalidDictionary))
                                    expect(addObserver.events.first!.value.element).to(beNil())
                                }
                            }

                            describe("when the parser is able to parse items from the dictionary") {
                                beforeEach() {
                                    self.parser.itemFromDictionaryShouldThrow = false
                                    self.parser.item = Item.Builder()
                                            .origins(["www.blah.com"])
                                            .id("kdkjdsfsdf")
                                            .entry(ItemEntry.Builder().kind("login").build())
                                            .build()
                                    self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                                }

                                it("pushes the item") {
                                    expect(addObserver.events.first!.value.error).to(beNil())
                                    expect(addObserver.events.first!.value.element).to(equal(self.parser.item))
                                }
                            }
                        }
                    }
                }
            }

            describe(".deleteItem(item:)") {
                var deleteObserver = self.scheduler.createObserver(Any.self)

                beforeEach {
                    deleteObserver = self.scheduler.createObserver(Any.self)
                }

                describe("when given an item without an id") {
                    beforeEach {
                        self.subject.deleteItem(Item.Builder().build())
                                .asObservable()
                                .subscribe(deleteObserver)
                                .disposed(by: self.disposeBag)
                    }

                    it("pushes the NoIDProvided error and no value") {
                        expect(deleteObserver.events.first!.value.error).to(matchError(DataStoreError.NoIDPassed))
                        expect(deleteObserver.events.first!.value.element).to(beNil())
                    }
                }

                describe("when given an item with an ID") {
                    let id = "gdfkhjfdsmmmmmm12434hkd"
                    let item = Item.Builder()
                            .origins(["www.barf.com"])
                            .entry(ItemEntry.Builder()
                                    .kind("fart")
                                    .build())
                            .id(id)
                            .build()

                    describe("when the datastore is not initialized") {
                        beforeEach {
                            self.webView.firstBoolSingle = self.scheduler.createHotObservable([next(100, false)])
                                    .take(1)
                                    .asSingle()
                            self.subject.deleteItem(item)
                                    .asObservable()
                                    .subscribe(deleteObserver)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("pushes the DataStoreNotInitialized error and no value") {
                            expect(deleteObserver.events.first!.value.element).to(beNil())
                            expect(deleteObserver.events.first!.value.error).to(matchError(DataStoreError.NotInitialized))
                        }
                    }

                    describe("when the datastore is initialized but locked") {
                        beforeEach {
                            self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                    .take(1)
                                    .asSingle()
                            self.webView.secondBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                    .take(1)
                                    .asSingle()
                            self.subject.deleteItem(item)
                                    .asObservable()
                                    .subscribe(deleteObserver)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("pushes the DataStoreLocked error and no value") {
                            expect(deleteObserver.events.first!.value.element).to(beNil())
                            expect(deleteObserver.events.first!.value.error).to(matchError(DataStoreError.Locked))
                        }
                    }

                    describe("when the datastore is initialized & unlocked") {
                        beforeEach {
                            self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                    .take(1)
                                    .asSingle()
                            self.webView.secondBoolSingle = self.scheduler.createColdObservable([next(100, false)])
                                    .take(1)
                                    .asSingle()
                            self.webView.anySingle = self.scheduler.createColdObservable([next(100, false)])
                                    .take(1)
                                    .asSingle()

                            self.subject.deleteItem(item)
                                    .asObservable()
                                    .subscribe(deleteObserver)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("evaluates .delete() on the webview datastore") {
                            expect(self.webView.evaluateJSCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).remove(\"\(id)\")"))
                        }

                        describe("getting an unknown callback from javascript") {
                            beforeEach {
                                let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the UnexpectedJavaScriptMethod to the observer") {
                                expect(deleteObserver.events.first!.value.element).to(beNil())
                                expect(deleteObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedJavaScriptMethod))
                            }
                        }

                        describe("when the webview calls back with something") {
                            let body = "done"
                            beforeEach {
                                let message = FakeWKScriptMessage(name: JSCallbackFunction.DeleteComplete.rawValue, body: body)
                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the value to the observer") {
                                let value = deleteObserver.events.first!.value.element as! String
                                expect(deleteObserver.events.first!.value.error).to(beNil())
                                expect(value).to(equal(body))
                            }
                        }
                    }
                }
            }

            describe(".updateItem(item:)") {
                var updateObserver = self.scheduler.createObserver(Item.self)

                beforeEach {
                    updateObserver = self.scheduler.createObserver(Item.self)
                }

                describe("when given an item without an id") {
                    beforeEach {
                        self.subject.updateItem(Item.Builder().build())
                                .asObservable()
                                .subscribe(updateObserver)
                                .disposed(by: self.disposeBag)
                    }

                    it("pushes the NoIDProvided error and no value") {
                        expect(updateObserver.events.first!.value.error).to(matchError(DataStoreError.NoIDPassed))
                        expect(updateObserver.events.first!.value.element).to(beNil())
                    }
                }

                describe("when given an item with an ID") {
                    let id = "gdfkhjfdsmmmmmm12434hkd"
                    let item = Item.Builder()
                            .origins(["www.barf.com"])
                            .entry(ItemEntry.Builder()
                                    .kind("fart")
                                    .build())
                            .id(id)
                            .build()

                    describe("when the parser is not able to form a json string from the item") {
                        beforeEach {
                            self.parser.jsonStringFromItemShouldThrow = true
                            self.subject.updateItem(item)
                                    .asObservable()
                                    .subscribe(updateObserver)
                                    .disposed(by: self.disposeBag)
                        }

                        it("pushes the InvalidItem error") {
                            expect(updateObserver.events.first!.value.error).to(matchError(ParserError.InvalidItem))
                            expect(updateObserver.events.first!.value.element).to(beNil())
                        }
                    }
                    
                    describe("when the parser is able to form a json string from the item") {
                        let jsonString = "{ILOOKLIKJSONMAYBE:NOPE}"
                        beforeEach {
                            self.parser.jsonStringFromItemShouldThrow = false
                            self.parser.jsonString = jsonString
                        }

                        describe("when the datastore is not initialized") {
                            beforeEach {
                                self.webView.firstBoolSingle = self.scheduler.createHotObservable([next(100, false)])
                                        .take(1)
                                        .asSingle()
                                self.subject.updateItem(item)
                                        .asObservable()
                                        .subscribe(updateObserver)
                                        .disposed(by: self.disposeBag)
                                self.scheduler.start()
                            }

                            it("pushes the DataStoreNotInitialized error and no value") {
                                expect(updateObserver.events.first!.value.element).to(beNil())
                                expect(updateObserver.events.first!.value.error).to(matchError(DataStoreError.NotInitialized))
                            }
                        }

                        describe("when the datastore is initialized but locked") {
                            beforeEach {
                                self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                        .take(1)
                                        .asSingle()
                                self.webView.secondBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                        .take(1)
                                        .asSingle()
                                self.subject.updateItem(item)
                                        .asObservable()
                                        .subscribe(updateObserver)
                                        .disposed(by: self.disposeBag)
                                self.scheduler.start()
                            }

                            it("pushes the DataStoreLocked error and no value") {
                                expect(updateObserver.events.first!.value.element).to(beNil())
                                expect(updateObserver.events.first!.value.error).to(matchError(DataStoreError.Locked))
                            }
                        }

                        describe("when the datastore is initialized & unlocked") {
                            beforeEach {
                                self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                        .take(1)
                                        .asSingle()
                                self.webView.secondBoolSingle = self.scheduler.createColdObservable([next(100, false)])
                                        .take(1)
                                        .asSingle()

                                self.webView.anySingle = self.scheduler.createColdObservable([next(100, "standard success")])
                                        .take(1)
                                        .asSingle()

                                self.subject.updateItem(item)
                                        .asObservable()
                                        .subscribe(updateObserver)
                                        .disposed(by: self.disposeBag)
                                self.scheduler.start()
                            }

                            it("evaluates .update() on the webview datastore") {
                                expect(self.webView.evaluateJSCalled).to(beTrue())
                                expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).update(\(jsonString))"))
                            }
                            describe("getting an unknown callback from javascript") {
                                beforeEach {
                                    let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                                    self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                                }

                                it("pushes the UnexpectedJavaScriptMethod to the observer") {
                                    expect(updateObserver.events.first!.value.element).to(beNil())
                                    expect(updateObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedJavaScriptMethod))
                                }
                            }

                            describe("when the webview calls back with a non-dictionary") {
                                beforeEach {
                                    let message = FakeWKScriptMessage(name: JSCallbackFunction.UpdateComplete.rawValue, body: [["foo":5],["bar":1]])
                                    self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                                }

                                it("pushes the UnexpectedType error") {
                                    expect(updateObserver.events.first!.value.error).to(matchError(DataStoreError.UnexpectedType))
                                    expect(updateObserver.events.first!.value.element).to(beNil())
                                }
                            }

                            describe("when the webview calls back with a dictionary") {
                                let message = FakeWKScriptMessage(name: JSCallbackFunction.UpdateComplete.rawValue, body: ["foo": 5])

                                describe("when the parser is unable to parse items from the dictionary") {
                                    beforeEach() {
                                        self.parser.itemFromDictionaryShouldThrow = true
                                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                                    }

                                    it("pushes the InvalidDictionary error") {
                                        expect(updateObserver.events.first!.value.error).to(matchError(ParserError.InvalidDictionary))
                                        expect(updateObserver.events.first!.value.element).to(beNil())
                                    }
                                }

                                describe("when the parser is able to parse items from the dictionary") {
                                    beforeEach() {
                                        self.parser.itemFromDictionaryShouldThrow = false
                                        self.parser.item = Item.Builder()
                                                .origins(["www.blah.com"])
                                                .id("kdkjdsfsdf")
                                                .entry(ItemEntry.Builder().kind("login").build())
                                                .build()
                                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                                    }

                                    it("pushes the item") {
                                        expect(updateObserver.events.first!.value.error).to(beNil())
                                        expect(updateObserver.events.first!.value.element).to(equal(self.parser.item))
                                    }
                                }
                            }
                        }
                    }

                }
            }
        }
    }
}

















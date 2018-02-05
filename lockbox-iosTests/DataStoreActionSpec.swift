/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import WebKit
import RxTest
import RxSwift

@testable import Lockbox

class DataStoreActionSpec: QuickSpec {
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

    class FakeDispatcher : Dispatcher {
        var actionTypeArgument: Action?

        override func dispatch(action: Action) {
            self.actionTypeArgument = action
        }
    }

    var subject: DataStoreActionHandler!
    var webView: FakeWebView!
    var parser:FakeParser!
    var dispatcher:FakeDispatcher!
    private let dataStoreName: String = "dstore"
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()

    override func spec() {
        describe("DataStoreActionHandler") {
            beforeEach {
                self.webView = FakeWebView()
                self.parser = FakeParser()
                self.dispatcher = FakeDispatcher()
                self.subject = DataStoreActionHandler(dataStoreName: self.dataStoreName, parser:self.parser, dispatcher:self.dispatcher)

                self.subject.webView = self.webView
            }

            xdescribe(".webView(_:didFinish:") {
                // pended because of weird crash when deallocating wknavigation
                it("evaluates open() on the webview datastore") {
                    let fakeNav = FakeWKNavigation()
                    (self.subject as WKNavigationDelegate).webView!(self.webView, didFinish: fakeNav)
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("var \(self.dataStoreName);swiftOpen().then(function (datastore) {\(self.dataStoreName) = datastore;});"))
                }
            }

            describe(".updateInitialized()") {
                describe("when the datastore has not been opened yet") {
                    it("does nothing") {
                        self.subject.updateInitialized()
                        expect(self.webView.evaluateJSCalled).to(beFalse())
                        expect(self.dispatcher.actionTypeArgument).to(beNil())
                    }
                }

                describe("when the datastore has been opened") {
                    describe("when the bool is evaluated successfully") {
                        beforeEach {
                            let message = FakeWKScriptMessage(name: JSCallbackFunction.OpenComplete.rawValue, body: "opened")
                            self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(10, true)])
                                    .take(1)
                                    .asSingle()
                            self.subject.updateInitialized()
                            self.scheduler.start()
                        }

                        it("evaluates a bool from .initialized on the webview") {
                            expect(self.webView.evaluateJSToBoolCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).initialized"))
                        }

                        it("pushes the value from the webview to the returned single") {
                            expect(self.dispatcher.actionTypeArgument).toNot(beNil())
                            let argument = self.dispatcher.actionTypeArgument as! DataStoreAction
                            expect(argument).to(equal(DataStoreAction.initialized(initialized: true)))
                        }
                    }

                    describe("when there is a javascript or other webview error") {
                        let err = NSError(domain: "badness", code: -1)

                        beforeEach {
                            let message = FakeWKScriptMessage(name: JSCallbackFunction.OpenComplete.rawValue, body: "opened")
                            self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            self.webView.firstBoolSingle = self.scheduler.createColdObservable([error(10, err)])
                                    .take(1)
                                    .asSingle()
                            self.subject.updateInitialized()
                            self.scheduler.start()
                        }

                        it("evaluates a bool from .initialized on the webview") {
                            expect(self.webView.evaluateJSToBoolCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).initialized"))
                        }

                        it("pushes the error from the webview to the dispatcher") {
                            expect(self.dispatcher.actionTypeArgument).toEventuallyNot(beNil())
                            let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                            expect(argument).to(matchErrorAction(ErrorAction(error: err)))
                        }
                    }
                }
            }

            describe(".initialize(scopedKey:)") {
                let scopedKey = "someLongJWKStringWithQuote"
                let uid = "jfdsjkjewnmadsflsdf"

                describe("when the datastore has not been opened yet") {
                    beforeEach {
                        self.subject.initialize(scopedKey: scopedKey, uid: uid)
                    }

                    it("does nothing") {
                        expect(self.webView.evaluateJSCalled).to(beFalse())
                        expect(self.dispatcher.actionTypeArgument).to(beNil())
                    }
                }

                describe("when the datastore has been opened") {
                    beforeEach {
                        let message = FakeWKScriptMessage(name: JSCallbackFunction.OpenComplete.rawValue, body: "opened")
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    describe("when the javascript call results in an error") {
                        let err = NSError(domain: "badness", code: -1)

                        beforeEach {
                            self.webView.anySingle = self.scheduler.createColdObservable([error(100, err)])
                                    .take(1)
                                    .asSingle()
                            self.subject.initialize(scopedKey: scopedKey, uid: uid)
                            self.scheduler.start()
                        }

                        it("evaluates javascript to initialize the webview datastore") {
                            expect(self.webView.evaluateJSCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).initialize({\"appKey\":\(scopedKey), \"salt\":\"\(uid)\"})"))
                        }

                        it("dispatches the error") {
                            expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                            let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                            expect(argument).to(matchErrorAction(ErrorAction(error: err)))
                        }
                    }

                    describe("when the javascript call proceeds normally") {
                        beforeEach {
                            self.webView.anySingle = self.scheduler.createColdObservable([next(100, true)])
                                    .take(1)
                                    .asSingle()
                            self.subject.initialize(scopedKey: scopedKey, uid: uid)
                            self.scheduler.start()
                        }

                        it("evaluates javascript to initialize the webview datastore") {
                            expect(self.webView.evaluateJSCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).initialize({\"appKey\":\(scopedKey), \"salt\":\"\(uid)\"})"))
                        }

                        describe("getting an initializecomplete callback from javascript") {
                            beforeEach {
                                let message = FakeWKScriptMessage(name: JSCallbackFunction.InitializeComplete.rawValue, body: "initialized")
                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the initialized result to the dispatcher") {
                                expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                let argument = self.dispatcher.actionTypeArgument as! DataStoreAction
                                expect(argument).to(equal(DataStoreAction.initialized(initialized: true)))
                            }
                        }

                        describe("getting an unknown callback from javascript") {
                            beforeEach {
                                let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the UnexpectedJavaScriptMethod to the dispatcher") {
                                expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                                expect(argument).to(matchErrorAction(ErrorAction(error: DataStoreError.UnexpectedJavaScriptMethod)))
                            }
                        }
                    }
                }
            }

            describe(".updateLocked()") {
                describe("when the datastore has not been opened yet") {
                    it("does nothing") {
                        self.subject.updateLocked()
                        expect(self.webView.evaluateJSCalled).to(beFalse())
                        expect(self.dispatcher.actionTypeArgument).to(beNil())
                    }
                }

                describe("when the datastore has been opened") {
                    describe("when the bool is evaluated successfully") {
                        beforeEach {
                            let message = FakeWKScriptMessage(name: JSCallbackFunction.OpenComplete.rawValue, body: "opened")
                            self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                    .take(1)
                                    .asSingle()
                            self.subject.updateLocked()
                            self.scheduler.start()
                        }

                        it("evaluates a bool from .locked on the webview") {
                            expect(self.webView.evaluateJSToBoolCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).locked"))
                        }

                        it("pushes the value from the webview to the returned single") {
                            expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                            let argument = self.dispatcher.actionTypeArgument as! DataStoreAction
                            expect(argument).to(equal(DataStoreAction.locked(locked: true)))
                        }
                    }

                    describe("when there is a javascript or other webview error") {
                        let err = NSError(domain: "badness", code: -1)
                        beforeEach {
                            let message = FakeWKScriptMessage(name: JSCallbackFunction.OpenComplete.rawValue, body: "opened")
                            self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)

                            self.webView.firstBoolSingle = self.scheduler.createColdObservable([error(100, err)])
                                    .take(1)
                                    .asSingle()
                            self.subject.updateLocked()
                            self.scheduler.start()
                        }

                        it("evaluates a bool from .initialized on the webview") {
                            expect(self.webView.evaluateJSToBoolCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).locked"))
                        }

                        it("pushes the error from the webview to the dispatcher") {
                            expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                            let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                            expect(argument).to(matchErrorAction(ErrorAction(error: err)))
                        }
                    }
                }
            }
            describe(".unlock(scopedKey:)") {
                let scopedKey = "{\"kty\":\"oct\",\"kid\":\"L9-eBkDrYHdPdXV_ymuzy_u9n3drkQcSw5pskrNl4pg\",\"k\":\"WsTdZ2tjji2W36JN9vk9s2AYsvp8eYy1pBbKPgcSLL4\"}"
                describe("when the datastore has not been opened yet") {
                    it("does nothing") {
                        self.subject.unlock(scopedKey: scopedKey)
                        expect(self.webView.evaluateJSCalled).to(beFalse())
                        expect(self.dispatcher.actionTypeArgument).to(beNil())
                    }
                }

                describe("when the datastore has been opened") {
                    beforeEach {
                        let message = FakeWKScriptMessage(name: JSCallbackFunction.OpenComplete.rawValue, body: "opened")
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    describe("when the javascript call results in an error") {
                        let err = NSError(domain: "badness", code: -1)

                        beforeEach {
                            self.webView.anySingle = self.scheduler.createHotObservable([error(100, err)])
                                    .take(1)
                                    .asSingle()
                            self.subject.unlock(scopedKey: scopedKey)
                            self.scheduler.start()
                        }

                        it("evaluates .unlock on the webview datastore") {
                            expect(self.webView.evaluateJSCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).unlock(\(scopedKey))"))
                        }

                        it("dispatches the error") {
                            expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                            let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                            expect(argument).to(matchErrorAction(ErrorAction(error: err)))
                        }
                    }

                    describe("when the javascript call proceeds normally") {
                        beforeEach {
                            self.webView.anySingle = self.scheduler.createHotObservable([next(100, true)])
                                    .take(1)
                                    .asSingle()
                            self.subject.unlock(scopedKey: scopedKey)
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

                            it("pushes the value to the dispatcher") {
                                expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                let argument = self.dispatcher.actionTypeArgument as! DataStoreAction
                                expect(argument).to(equal(DataStoreAction.locked(locked: false)))
                            }
                        }

                        describe("getting an unknown callback from javascript") {
                            beforeEach {
                                let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the UnexpectedJavaScriptMethod to the dispatcher") {
                                expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                                expect(argument).to(matchErrorAction(ErrorAction(error: DataStoreError.UnexpectedJavaScriptMethod)))
                            }
                        }
                    }
                }
            }

            describe(".lock()") {
                describe("when the datastore has not been opened yet") {
                    it("does nothing") {
                        expect(self.webView.evaluateJSCalled).to(beFalse())
                        expect(self.dispatcher.actionTypeArgument).to(beNil())
                    }
                }

                describe("when the datastore has been opened") {
                    beforeEach {
                        let message = FakeWKScriptMessage(name: JSCallbackFunction.OpenComplete.rawValue, body: "opened")
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    describe("when the javascript call results in an error") {
                        let err = NSError(domain: "badness", code: -1)

                        beforeEach {
                            self.webView.anySingle = self.scheduler.createColdObservable([error(100, err)])
                                    .take(1)
                                    .asSingle()
                            self.subject.lock()
                            self.scheduler.start()
                        }

                        it("evaluates .lock on the webview datastore") {
                            expect(self.webView.evaluateJSCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).lock()"))
                        }

                        it("dispatches the error") {
                            expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                            let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                            expect(argument).to(matchErrorAction(ErrorAction(error: err)))
                        }
                    }

                    describe("when the javascript call proceeds normally") {
                        beforeEach {
                            self.webView.anySingle = self.scheduler.createColdObservable([next(100, true)])
                                    .take(1)
                                    .asSingle()
                            self.subject.lock()
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

                            it("pushes the updated lock value to the dispatcher") {
                                expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                let argument = self.dispatcher.actionTypeArgument as! DataStoreAction
                                expect(argument).to(equal(DataStoreAction.locked(locked: true)))
                            }
                        }

                        describe("getting an unknown callback from javascript") {
                            beforeEach {
                                let message = FakeWKScriptMessage(name: "gibberish", body: "something")
                                self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                            }

                            it("pushes the UnexpectedJavaScriptMethod to the dispatcher") {
                                expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                                expect(argument).to(matchErrorAction(ErrorAction(error: DataStoreError.UnexpectedJavaScriptMethod)))
                            }
                        }
                    }
                }
            }

            describe(".list()") {
                describe("when the datastore is not open") {
                    it("does nothing") {
                        self.subject.list()
                        expect(self.dispatcher.actionTypeArgument).to(beNil())
                        expect(self.webView.evaluateJSCalled).to(beFalse())
                    }
                }

                describe("when the datastore is open") {
                    beforeEach {
                        let message = FakeWKScriptMessage(name: JSCallbackFunction.OpenComplete.rawValue, body: "opened")
                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                    }

                    describe("when the datastore is not initialized") {
                        beforeEach {
                            self.webView.firstBoolSingle = self.scheduler.createHotObservable([next(100, false)])
                                    .take(1)
                                    .asSingle()
                            self.subject.list()
                            self.scheduler.start()
                        }

                        it("pushes the DataStoreNotInitialized error") {
                            expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                            let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                            expect(argument).to(matchErrorAction(ErrorAction(error: DataStoreError.NotInitialized)))
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
                            self.scheduler.start()
                        }

                        it("pushes the DataStoreLocked error") {
                            expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                            let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                            expect(argument).to(matchErrorAction(ErrorAction(error: DataStoreError.Locked)))
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
                        }

                        describe("when the javascript call results in an error") {
                            let err = NSError(domain: "badness", code: -1)

                            beforeEach {
                                self.webView.anySingle = self.scheduler.createColdObservable([error(100, err)])
                                        .take(1)
                                        .asSingle()

                                self.subject.list()
                                self.scheduler.start()
                            }

                            it("evaluates .list() on the webview datastore") {
                                expect(self.webView.evaluateJSCalled).to(beTrue())
                                expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).list()"))
                            }

                            it("dispatches the error") {
                                expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                                expect(argument).to(matchErrorAction(ErrorAction(error: err)))
                            }
                        }
                        describe("when the javascript call proceeds normally") {
                            beforeEach {
                                self.webView.anySingle = self.scheduler.createColdObservable([next(200, "initial success")])
                                        .take(1)
                                        .asSingle()

                                self.subject.list()
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

                                it("pushes the UnexpectedJavaScriptMethod to the dispatcher") {
                                    expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                    let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                                    expect(argument).to(matchErrorAction(ErrorAction(error: DataStoreError.UnexpectedJavaScriptMethod)))
                                }
                            }

                            describe("when the webview calls back with a list that does not contain lists") {
                                beforeEach {
                                    let message = FakeWKScriptMessage(name: JSCallbackFunction.ListComplete.rawValue, body: [1,2,3])
                                    self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                                }

                                it("pushes the UnexpectedType error") {
                                    expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                    let argument = self.dispatcher.actionTypeArgument as! ErrorAction
                                    expect(argument).to(matchErrorAction(ErrorAction(error: DataStoreError.UnexpectedType)))
                                }
                            }


                            describe("when the webview calls back with a list of lists without the dictionary as the second value") {
                                beforeEach {
                                    let message = FakeWKScriptMessage(name: JSCallbackFunction.ListComplete.rawValue, body: [[1,2,3]])
                                    self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                                }

                                it("pushes an empty list") {
                                    expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                    let argument = self.dispatcher.actionTypeArgument as! DataStoreAction
                                    expect(argument).to(equal(DataStoreAction.list(list: [])))
                                }
                            }

                            describe("when the webview calls back with a list that contains only dictionaries") {
                                describe("when the parser is unable to parse an item from the dictionary") {
                                    beforeEach() {
                                        self.parser.itemFromDictionaryShouldThrow = true
                                        let message = FakeWKScriptMessage(name: JSCallbackFunction.ListComplete.rawValue, body: [["idvalue",["foo":5,"bar":1]],["idvalue1",["foo":3,"bar":7]]])

                                        self.subject.userContentController(self.webView.configuration.userContentController, didReceive: message)
                                    }

                                    it("pushes a list with the valid items") {
                                        expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                        let argument = self.dispatcher.actionTypeArgument as! DataStoreAction
                                        expect(argument).to(equal(DataStoreAction.list(list: [])))
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
                                        expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                                        let argument = self.dispatcher.actionTypeArgument as! DataStoreAction
                                        expect(argument).to(equal(DataStoreAction.list(list: [self.parser.item, self.parser.item])))
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        describe("Action equality") {
            let itemA = Item.Builder().id("something").build()
            let itemB = Item.Builder().id("something else").build()

            it("updateList is equal based on the contained list") {
                expect(DataStoreAction.list(list: [itemA])).to(equal(DataStoreAction.list(list: [itemA])))
                expect(DataStoreAction.list(list: [itemA])).notTo(equal(DataStoreAction.list(list: [itemA, itemA])))
                expect(DataStoreAction.list(list: [itemA])).notTo(equal(DataStoreAction.list(list: [itemB])))
            }

            it("initialize is equal based on the contained boolean") {
                expect(DataStoreAction.initialized(initialized: true)).to(equal(DataStoreAction.initialized(initialized: true)))
                expect(DataStoreAction.initialized(initialized: true)).notTo(equal(DataStoreAction.initialized(initialized: false)))
            }

            it("initialize is equal based on the contained boolean") {
                expect(DataStoreAction.locked(locked: true)).to(equal(DataStoreAction.locked(locked: true)))
                expect(DataStoreAction.locked(locked: true)).notTo(equal(DataStoreAction.locked(locked: false)))
            }

            it("different enum values are not equal") {
                expect(DataStoreAction.locked(locked: false)).notTo(equal(DataStoreAction.initialized(initialized: false)))
            }
        }
    }
}

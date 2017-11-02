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
        var evaluateJSToStringCalled: Bool = false
        var evaluateJSToArrayCalled: Bool = false
        var evaluateJSCalled: Bool = false

        var evaluateJSArgument = ""

        var loadFileUrlArgument = URL(string: "")
        var loadFileBaseUrlArgument = URL(string: "")

        var firstBoolSingle: Single<Bool>?
        var secondBoolSingle: Single<Bool>?
        var stringSingle: Single<String>?
        var arraySingle: Single<[Any]>?
        var anySingle: Single<Any> = Single.just(false)

        private var boolCallCount = 0

        func evaluateJavaScriptToBool(_ javaScriptString: String) -> Single<Bool> {
            evaluateJSToBoolCalled = true
            evaluateJSArgument = javaScriptString

            boolCallCount += 1
            return boolCallCount == 1 ? firstBoolSingle! : secondBoolSingle!
        }

        func evaluateJavaScriptToString(_ javaScriptString: String) -> Single<String> {
            evaluateJSToStringCalled = true
            evaluateJSArgument = javaScriptString

            return stringSingle!
        }

        func evaluateJavaScriptMapToArray(_ javaScriptString: String) -> Single<[Any]> {
            evaluateJSToArrayCalled = true
            evaluateJSArgument = javaScriptString

            return arraySingle!
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

    var subject: DataStore!
    var webView: FakeWebView!
    private let dataStoreName: String = "dstore"
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()

    override func spec() {
        describe("DataStore") {

            beforeEach {
                self.webView = FakeWebView()
                self.subject = DataStore(webview: self.webView, dataStoreName: self.dataStoreName)
            }

            describe(".init(webView:, dataStoreName:)") {
                it("loads the correct local js & html") {
                    expect(self.webView.loadFileUrlArgument).to(equal(URL(string: "file://\(Bundle.main.bundlePath)/lockbox-datastore/index.html")))
                    expect(self.webView.loadFileBaseUrlArgument).to(equal(URL(string: "file://\(Bundle.main.bundlePath)/lockbox-datastore/")))
                }
            }

            describe(".open()") {
                it("evaluates open() on the webview datastore") {
                    let _ = self.subject.open()
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("var \(self.dataStoreName);DataStoreModule.open().then((function (datastore) {\(self.dataStoreName) = datastore;}));"))
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

            describe(".initialize(password:)") {
                let password = "someLongPasswordStringWithQuote"
                beforeEach {
                    let _ = self.subject.initialize(password: password)
                }

                it("evaluates javascript to initialize the webview datastore") {
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).initialize({password:\"\(password)\",})"))
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
                }
            }

            describe(".unlock(password:)") {
                let password = "somePasswordString"
                beforeEach {
                    let _ = self.subject.unlock(password: password)
                }

                it("evalutes .unlock on the webview datastore") {
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).unlock(\"\(password)\")"))
                }
            }

            describe(".lock()") {
                beforeEach {
                    let _ = self.subject.lock()
                }

                it("evaluates .lock on the webview datastore") {
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).lock()"))
                }
            }

            describe(".getItem(item:)") {
                let id = "dfslkjdfslkjsdf"
                var observer = self.scheduler.createObserver(Item.self)

                beforeEach {
                    observer = self.scheduler.createObserver(Item.self)
                }

                describe("when the datastore is not initialized") {
                    beforeEach {
                        self.webView.firstBoolSingle = self.scheduler.createHotObservable([next(100, false)])
                                .take(1)
                                .asSingle()
                        self.subject.getItem(id)
                                .asObservable()
                                .subscribe(observer)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("pushes the DataStoreNotInitialized error and no value") {
                        expect(observer.events.first!.value.element).to(beNil())
                        expect(observer.events.first!.value.error).to(matchError(DataStoreError.NotInitialized))
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
                                .subscribe(observer)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("pushes the DataStoreLocked error and no value") {
                        expect(observer.events.first!.value.element).to(beNil())
                        expect(observer.events.first!.value.error).to(matchError(DataStoreError.Locked))
                    }
                }

                describe("when the datastore is initialized & unlocked") {
                    beforeEach {
                        self.webView.anySingle = self.scheduler.createColdObservable([next(100, ["origins": ["blah"], "entry": ["kind": "login"]])])
                                .take(1)
                                .asSingle()
                        self.webView.firstBoolSingle = self.scheduler.createColdObservable([next(100, true)])
                                .take(1)
                                .asSingle()
                        self.webView.secondBoolSingle = self.scheduler.createColdObservable([next(100, false)])
                                .take(1)
                                .asSingle()
                        self.subject.getItem(id)
                                .asObservable()
                                .subscribe(observer)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("evaluates .get() on the webview datastore") {
                        expect(self.webView.evaluateJSCalled).to(beTrue())
                        expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).get(\"\(id)\")"))
                    }
                }
            }

            describe(".addItem(item:)") {
                let itemBuilder = Item.Builder()
                        .origins(["www.barf.com"])
                        .entry(ItemEntry.Builder().type("fart").build())
                var observer = self.scheduler.createObserver(Any.self)
                beforeEach {
                    observer = self.scheduler.createObserver(Any.self)
                }

                describe("when the datastore is not initialized") {
                    beforeEach {
                        self.webView.firstBoolSingle = self.scheduler.createHotObservable([next(100, false)])
                                .take(1)
                                .asSingle()
                        self.subject.addItem(itemBuilder.build())
                                .asObservable()
                                .subscribe(observer)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("pushes the DataStoreNotInitialized error and no value") {
                        expect(observer.events.first!.value.element).to(beNil())
                        expect(observer.events.first!.value.error).to(matchError(DataStoreError.NotInitialized))
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
                                .subscribe(observer)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("pushes the DataStoreLocked error and no value") {
                        expect(observer.events.first!.value.element).to(beNil())
                        expect(observer.events.first!.value.error).to(matchError(DataStoreError.Locked))
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
                        self.subject.addItem(itemBuilder.build())
                                .asObservable()
                                .subscribe(observer)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("evaluates .add() on the webview datastore with the correctly-JSONified item when given an item without an ID") {
                        expect(self.webView.evaluateJSCalled).to(beTrue())
                        expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).add(\(try! Parser.jsonStringFromItem(itemBuilder.build())))"))
                    }
                }
            }

            describe(".deleteItem(item:)") {
                var observer = self.scheduler.createObserver(Any.self)

                beforeEach {
                    observer = self.scheduler.createObserver(Any.self)
                }

                describe("when given an item without an id") {
                    beforeEach {
                        self.subject.deleteItem(Item.Builder().build())
                                .asObservable()
                                .subscribe(observer)
                                .disposed(by: self.disposeBag)
                    }

                    it("pushes the NoIDProvided error and no value") {
                        expect(observer.events.first!.value.error).to(matchError(DataStoreError.NoIDPassed))
                        expect(observer.events.first!.value.element).to(beNil())
                    }
                }

                describe("when given an item with an ID") {
                    let id = "gdfkhjfdsmmmmmm12434hkd"
                    let item = Item.Builder()
                            .origins(["www.barf.com"])
                            .entry(ItemEntry.Builder()
                                    .type("fart")
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
                                    .subscribe(observer)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("pushes the DataStoreNotInitialized error and no value") {
                            expect(observer.events.first!.value.element).to(beNil())
                            expect(observer.events.first!.value.error).to(matchError(DataStoreError.NotInitialized))
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
                                    .subscribe(observer)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("pushes the DataStoreLocked error and no value") {
                            expect(observer.events.first!.value.element).to(beNil())
                            expect(observer.events.first!.value.error).to(matchError(DataStoreError.Locked))
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
                            self.subject.deleteItem(item)
                                    .asObservable()
                                    .subscribe(observer)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("evaluates .delete() on the webview datastore") {
                            expect(self.webView.evaluateJSCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).delete(\"\(id)\")"))
                        }
                    }
                }
            }

            describe(".updateItem(item:)") {
                var observer = self.scheduler.createObserver(Any.self)

                beforeEach {
                    observer = self.scheduler.createObserver(Any.self)
                }

                describe("when given an item without an id") {
                    beforeEach {
                        self.subject.updateItem(Item.Builder().build())
                                .asObservable()
                                .subscribe(observer)
                                .disposed(by: self.disposeBag)
                    }

                    it("pushes the NoIDProvided error and no value") {
                        expect(observer.events.first!.value.error).to(matchError(DataStoreError.NoIDPassed))
                        expect(observer.events.first!.value.element).to(beNil())
                    }
                }

                describe("when given an item with an ID") {
                    let id = "gdfkhjfdsmmmmmm12434hkd"
                    let item = Item.Builder()
                            .origins(["www.barf.com"])
                            .entry(ItemEntry.Builder()
                                    .type("fart")
                                    .build())
                            .id(id)
                            .build()

                    describe("when the datastore is not initialized") {
                        beforeEach {
                            self.webView.firstBoolSingle = self.scheduler.createHotObservable([next(100, false)])
                                    .take(1)
                                    .asSingle()
                            self.subject.updateItem(item)
                                    .asObservable()
                                    .subscribe(observer)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("pushes the DataStoreNotInitialized error and no value") {
                            expect(observer.events.first!.value.element).to(beNil())
                            expect(observer.events.first!.value.error).to(matchError(DataStoreError.NotInitialized))
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
                                    .subscribe(observer)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("pushes the DataStoreLocked error and no value") {
                            expect(observer.events.first!.value.element).to(beNil())
                            expect(observer.events.first!.value.error).to(matchError(DataStoreError.Locked))
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
                            self.subject.updateItem(item)
                                    .asObservable()
                                    .subscribe(observer)
                                    .disposed(by: self.disposeBag)
                            self.scheduler.start()
                        }

                        it("evaluates .update() on the webview datastore") {
                            expect(self.webView.evaluateJSCalled).to(beTrue())
                            expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).update(\(try! Parser.jsonStringFromItem(item)))"))
                        }
                    }
                }
            }
        }
    }
}

















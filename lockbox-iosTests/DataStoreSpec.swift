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

        var boolSingle: Single<Bool>?
        var stringSingle: Single<String>?
        var arraySingle: Single<[Any]>?
        var anySingle: Single<Any>?

        func evaluateJavaScriptToBool(_ javaScriptString: String) -> Single<Bool> {
            evaluateJSToBoolCalled = true
            evaluateJSArgument = javaScriptString

            return boolSingle!
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

            return anySingle!
        }

        func evaluateJavaScript(_ javaScriptString: String) -> Completable {
            evaluateJSCalled = true
            evaluateJSArgument = javaScriptString

            return Completable.create() { completable in
                completable(.completed)
                return Disposables.create()
            }
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
                    self.webView.boolSingle = self.scheduler.createHotObservable([next(100, true)])
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
                    self.webView.boolSingle = self.scheduler.createHotObservable([next(100, false)])
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

                it("evalutes .lock on the webview datastore") {
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).lock()"))
                }
            }

            describe(".addItem(item:)") {
                let itemBuilder = Item.Builder()
                        .origins(["www.barf.com"])
                        .entry(ItemEntry.Builder().type("fart").build())

                it("evalutes .add() on the webview datastore with the correctly-JSONified item when given an item without an ID") {
                    let _ = self.subject.addItem(itemBuilder.build())
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).add(\(Parser.jsonStringFromItem(itemBuilder.build())))"))
                }
            }

            describe(".deleteItem(item:)") {
                let id = "gdfkhjfdsmmmmmm12434hkd"
                let itemBuilder = Item.Builder()
                        .origins(["www.barf.com"])
                        .entry(ItemEntry.Builder()
                                .type("fart")
                                .build())
                var item: Item?

                it("evaluates .delete() on the webview datastore given an item with an ID") {
                    item = itemBuilder.id(id).build()
                    let _ = self.subject.deleteItem(item!)

                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).delete(\"\(id)\")"))
                }
            }

            describe(".updateItem(item:)") {
                let itemBuilder = Item.Builder()
                        .origins(["www.mozilla.com"])
                        .entry(ItemEntry.Builder()
                                .type("login")
                                .build())

                it("evaluates .update() in the webview datastore") {
                    let item = itemBuilder.id("fdsjklfdsjkldsf").build()
                    let _ = self.subject.updateItem(item)

                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJSArgument).to(equal("\(self.dataStoreName).update(\(Parser.jsonStringFromItem(itemBuilder.build())))"))
                }
            }
        }
    }
}

















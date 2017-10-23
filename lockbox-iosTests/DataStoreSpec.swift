import Quick
import Nimble
import WebKit

@testable import lockbox_ios

class DataStoreSpec: QuickSpec {
    class FakeWebView: WKWebView, TypedJavaScriptWebView {
        var evaluateJSToBoolCalled: Bool = false
        var evaluateJSToStringCalled: Bool = false
        var evaluateJSToArrayCalled: Bool = false
        var evaluateJSCalled: Bool = false

        var evaluateJavaScriptArgument = ""

        var loadFileUrlArgument = URL(string: "")
        var loadFileBaseUrlArgument = URL(string: "")

        var boolCompletionHandler: ((Bool?, Error?) -> Void)?
        var stringCompletionHandler: ((String?, Error?) -> Void)?
        var arrayCompletionHandler: (([Any]?, Error?) -> Void)?

        func evaluateJavaScriptToBool(_ javaScriptString: String, completionHandler: ((Bool?, Error?) -> Void)?) {
            evaluateJSToBoolCalled = true
            evaluateJavaScriptArgument = javaScriptString
            boolCompletionHandler = completionHandler
        }

        func evaluateJavaScriptToString(_ javaScriptString: String, completionHandler: ((String?, Error?) -> Void)?) {
            evaluateJSToStringCalled = true
            evaluateJavaScriptArgument = javaScriptString
            stringCompletionHandler = completionHandler
        }

        func evaluateJavaScriptMapToArray(_ javaScriptString: String, completionHandler: (([Any]?, Error?) -> Void)?) {
            evaluateJSToArrayCalled = true
            evaluateJavaScriptArgument = javaScriptString
            arrayCompletionHandler = completionHandler
        }

        override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
            evaluateJSCalled = true
            evaluateJavaScriptArgument = javaScriptString
        }

        override func loadFileURL(_ URL: URL, allowingReadAccessTo readAccessURL: URL) -> WKNavigation? {
            loadFileUrlArgument = URL
            loadFileBaseUrlArgument = readAccessURL

            return nil
        }
    }

    var subject: DataStore!
    var webView: FakeWebView!
    let dataStoreName: String = "dstore"

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

                it("initializes the webview datastore after loading the local files") {
                    self.subject.webView(self.webView, didFinish: nil)

                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJavaScriptArgument).to(equal("var \(self.dataStoreName);DataStoreModule.open().then((function (datastore) {\(self.dataStoreName) = datastore;}));"))
                }
            }

            describe(".initalized(completionHandler:)") {
                var evaluatedValue: Bool?
                beforeEach {
                    self.subject.initialized(completionHandler: { (value) in
                        evaluatedValue = value
                    })
                }

                it("evaluates javascript to query the initialization status of the webview datastore") {
                    expect(self.webView.evaluateJSToBoolCalled).to(beTrue())
                    expect(self.webView.evaluateJavaScriptArgument).to(equal("\(self.dataStoreName).initialized"))
                }

                describe("when js callback returns nil") {
                    it("calls completion handler with false") {
                        self.webView.boolCompletionHandler!(nil, nil)
                        expect(evaluatedValue).to(beFalse())
                    }
                }

                describe("when js callback returns true") {
                    it("calls completion handler with true") {
                        self.webView.boolCompletionHandler!(true, nil)
                        expect(evaluatedValue).to(beTrue())
                    }
                }

                describe("when js callback returns false") {
                    it("calls completion handler with false") {
                        self.webView.boolCompletionHandler!(false, nil)
                        expect(evaluatedValue).to(beFalse())
                    }
                }
            }

            describe(".initialize(password:)") {
                let password = "someLongPasswordStringWithQuote"
                beforeEach {
                    self.subject.initialize(password: password)
                }

                it("evaluates javascript to initialize the webview datastore") {
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJavaScriptArgument).to(equal("\(self.dataStoreName).initialize({password:\"\(password)\",})"))
                }
            }

            describe(".locked(completionHandler:)") {
                var evaluatedValue: Bool?
                beforeEach {
                    self.subject.locked(completionHandler: { (value) in
                        evaluatedValue = value
                    })
                }

                it("evaluates javascript to query the lock status of the webview datastore") {
                    expect(self.webView.evaluateJSToBoolCalled).to(beTrue())
                    expect(self.webView.evaluateJavaScriptArgument).to(equal("\(self.dataStoreName).locked"))
                }

                describe("when js callback returns nil") {
                    it("calls completion handler with false") {
                        self.webView.boolCompletionHandler!(nil, nil)
                        expect(evaluatedValue).to(beFalse())
                    }
                }

                describe("when js callback returns true") {
                    it("calls completion handler with true") {
                        self.webView.boolCompletionHandler!(true, nil)
                        expect(evaluatedValue).to(beTrue())
                    }
                }

                describe("when js callback returns false") {
                    it("calls completion handler with false") {
                        self.webView.boolCompletionHandler!(false, nil)
                        expect(evaluatedValue).to(beFalse())
                    }
                }
            }

            describe(".unlock(password:)") {
                let password = "somePasswordString"
                beforeEach {
                    self.subject.unlock(password: password)
                }

                it("evalutes .unlock on the webview datastore") {
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJavaScriptArgument).to(equal("\(self.dataStoreName).unlock(\"\(password)\")"))
                }
            }

            describe(".lock()") {
                beforeEach {
                    self.subject.lock()
                }

                it("evalutes .lock on the webview datastore") {
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJavaScriptArgument).to(equal("\(self.dataStoreName).lock()"))
                }
            }

            describe(".addItem(item:)") {
                let itemBuilder = Item.Builder()
                        .origins(["www.barf.com"])
                        .entry(ItemEntry.Builder().type("fart").build())

                it("evalutes .add() on the webview datastore with the correctly-JSONified item when given an item without an ID") {
                    self.subject.addItem(itemBuilder.build())
                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJavaScriptArgument).to(equal("\(self.dataStoreName).add(\(Parser.jsonStringFromItem(itemBuilder.build())))"))
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
                    try! self.subject.deleteItem(item!)

                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJavaScriptArgument).to(equal("\(self.dataStoreName).delete(\"\(id)\")"))
                }

                it("throws an error when given an item without an id") {
                    item = itemBuilder.build()
                    expect {
                        try self.subject.deleteItem(item!)
                    }.to(throwError(DataStoreError.NoIDPassed))
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
                    try! self.subject.updateItem(item)

                    expect(self.webView.evaluateJSCalled).to(beTrue())
                    expect(self.webView.evaluateJavaScriptArgument).to(equal("\(self.dataStoreName).update(\(Parser.jsonStringFromItem(itemBuilder.build())))"))
                }

                it("throws an error when given an item without an id") {
                    let item = itemBuilder.id("fdsjklfdsjkldsf").build()
                    
                    expect(try self.subject.updateItem(item)).to(throwError(DataStoreError.NoIDPassed))
                }
            }
        }
    }
}

















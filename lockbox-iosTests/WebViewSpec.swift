/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import WebKit
import RxTest
import RxSwift
import RxBlocking

@testable import lockbox_ios

class WebViewSpec: QuickSpec {
    class StubbedEvaluateJSWebView: WebView {
        var evaluateJSArguments:[String] = []
        var evaluateJSCompletion: ((Any?, Error?) -> Void)?

        override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)?) {
            evaluateJSArguments.append(javaScriptString)
            evaluateJSCompletion = completionHandler
        }
    }

    class StubbedEvaluateJSSingleWebView: StubbedEvaluateJSWebView {
        var evaluateJSSingleCalled: Bool = false
        var evaluateJSSingleArgument: String?
        var observable: Single<Any>?

        override func evaluateJavaScript(_ javaScriptString: String) -> Single<Any> {
            self.evaluateJSSingleCalled = true
            self.evaluateJSSingleArgument = javaScriptString
            return observable!
        }
    }

    var stubbedJSSingleSuper: StubbedEvaluateJSSingleWebView!
    var stubbedJSSuper: StubbedEvaluateJSWebView!
    var subject: WebView!
    var scheduler = TestScheduler(initialClock: 0)
    let disposeBag = DisposeBag()

    override func spec() {
        describe("WebView") {
            let javaScriptString = "console.log(butts)"

            describe(".evaluateJavaScript(javaScriptString:)") {
                var anyObserver: TestableObserver<Any>!

                beforeEach {
                    self.stubbedJSSuper = StubbedEvaluateJSWebView()
                    self.subject = self.stubbedJSSuper
                    anyObserver = self.scheduler.createObserver(Any.self)

                    self.subject.evaluateJavaScript(javaScriptString)
                            .asObservable()
                            .subscribe(anyObserver)
                            .disposed(by: self.disposeBag)
                }

                it("evaluates the javascript using the wkwebview method") {
                    expect(self.stubbedJSSuper.evaluateJSArguments.last).to(equal(javaScriptString))
                }

                describe("when provided an unsupported type webkit error") {
                    let wkError = WKError(_nsError: NSError(domain: "WKErrorDomain", code: 5))
                    beforeEach {
                        self.stubbedJSSuper.evaluateJSCompletion!(nil, wkError)
                    }

                    it("pushes a dummy single to the observer") {
                        let value = anyObserver.events.first!.value
                        expect(value.element as? String).to(equal(""))
                        expect(value.error).to(beNil())
                    }
                }

                describe("when provided any other webkit error") {
                    let wkError = WKError(_nsError: NSError(domain: "WKErrorDomain", code: 3))
                    beforeEach {
                        self.stubbedJSSuper.evaluateJSCompletion!(nil, wkError)
                    }

                    it("pushes the error to the observer") {
                        let value = anyObserver.events.first!.value
                        expect(value.element).to(beNil())
                        expect(value.error).to(matchError(wkError))
                    }
                }

                describe("when provided a non-webkit error") {
                    let error = NSError(domain: "something", code: -1)
                    beforeEach {
                        self.stubbedJSSuper.evaluateJSCompletion!(nil, error)
                    }

                    it("pushes the error to the observer") {
                        let value = anyObserver.events.first!.value
                        expect(value.element).to(beNil())
                        expect(value.error).to(matchError(error))
                    }
                }

                describe("when provided a value and no error") {
                    let completionValue = ["I am a valid js thingy"]
                    beforeEach {
                        self.stubbedJSSuper.evaluateJSCompletion!(completionValue, nil)
                    }

                    it("pushes the value to the observer") {
                        let value = anyObserver.events.first!.value
                        expect(value.element as? [String]).to(equal(completionValue))
                        expect(value.error).to(beNil())
                    }
                }

                describe("when provided no value and no error") {
                    beforeEach {
                        self.stubbedJSSuper.evaluateJSCompletion!(nil, nil)
                    }

                    it("pushes an unknown error to the observer") {
                        let value = anyObserver.events.first!.value
                        expect(value.element).to(beNil())
                        expect(value.error).to(matchError(WebViewError.Unknown))
                    }

                }
            }

            describe(".evaluateJavaScriptToBool(javaScriptString:)") {
                var boolObserver: TestableObserver<Bool>!

                beforeEach {
                    self.stubbedJSSingleSuper = StubbedEvaluateJSSingleWebView()
                    self.subject = self.stubbedJSSingleSuper
                    boolObserver = self.scheduler.createObserver(Bool.self)
                }

                describe("when provided a bool value") {
                    beforeEach {
                        self.stubbedJSSingleSuper.observable = self.scheduler.createHotObservable([next(50, true)])
                                .take(1)
                                .asSingle()

                        self.subject.evaluateJavaScriptToBool(javaScriptString)
                                .asObservable()
                                .subscribe(boolObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedJSSingleSuper.evaluateJSSingleCalled).to(beTrue())
                        expect(self.stubbedJSSingleSuper.evaluateJSSingleArgument).to(equal(javaScriptString))
                    }

                    it("pushes the boolean value out to the single with no error") {
                        let value = boolObserver.events.first!.value
                        expect(value.element).to(beTrue())
                        expect(value.error).to(beNil())
                    }
                }

                describe("when provided a non-bool value") {
                    beforeEach {
                        self.stubbedJSSingleSuper.observable = self.scheduler.createHotObservable([next(100, "blarg")])
                                .take(1)
                                .asSingle()
                        self.subject.evaluateJavaScriptToBool(javaScriptString)
                                .asObservable()
                                .subscribe(boolObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedJSSingleSuper.evaluateJSSingleCalled).to(beTrue())
                        expect(self.stubbedJSSingleSuper.evaluateJSSingleArgument).to(equal(javaScriptString))
                    }

                    it("pushes the a no bool error out to the single with no value") {
                        let value = boolObserver.events.first!.value
                        expect(value.element).to(beNil())
                        expect(value.error).to(matchError(WebViewError.ValueNotBool))
                    }
                }
            }

            describe(".evaluateJavaScriptToString(javaScriptString:)") {
                var stringObserver: TestableObserver<String>!

                beforeEach {
                    self.stubbedJSSingleSuper = StubbedEvaluateJSSingleWebView()
                    self.subject = self.stubbedJSSingleSuper
                    stringObserver = self.scheduler.createObserver(String.self)
                }

                describe("when provided a string value") {
                    beforeEach {
                        self.stubbedJSSingleSuper.observable = self.scheduler.createHotObservable([next(50, "purple")])
                                .take(1)
                                .asSingle()

                        self.subject.evaluateJavaScriptToString(javaScriptString)
                                .asObservable()
                                .subscribe(stringObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedJSSingleSuper.evaluateJSSingleCalled).to(beTrue())
                        expect(self.stubbedJSSingleSuper.evaluateJSSingleArgument).to(equal(javaScriptString))
                    }

                    it("pushes the string value out to the single with no error") {
                        let value = stringObserver.events.first!.value
                        expect(value.element).to(equal("purple"))
                        expect(value.error).to(beNil())
                    }
                }

                describe("when provided a non-string value") {
                    beforeEach {
                        self.stubbedJSSingleSuper.observable = self.scheduler.createHotObservable([next(100, false)])
                                .take(1)
                                .asSingle()
                        self.subject.evaluateJavaScriptToString(javaScriptString)
                                .asObservable()
                                .subscribe(stringObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedJSSingleSuper.evaluateJSSingleCalled).to(beTrue())
                        expect(self.stubbedJSSingleSuper.evaluateJSSingleArgument).to(equal(javaScriptString))
                    }

                    it("pushes the no string error out to the single with no value") {
                        let value = stringObserver.events.first!.value
                        expect(value.element).to(beNil())
                        expect(value.error).to(matchError(WebViewError.ValueNotString))
                    }
                }
            }

            describe(".evaluateJavaScriptMapToArray()") {
                var arrayObserver: TestableObserver<[Any]>!

                beforeEach {
                    arrayObserver = self.scheduler.createObserver([Any].self)
                    self.stubbedJSSingleSuper = StubbedEvaluateJSSingleWebView()
                    self.subject = self.stubbedJSSingleSuper

                    self.subject.evaluateJavaScriptMapToArray(javaScriptString)
                            .asObservable()
                            .subscribe(arrayObserver)
                            .disposed(by: self.disposeBag)
                }

                it("evaluates the expanded js string with the passed parameter") {
                    expect(self.stubbedJSSingleSuper.evaluateJSArguments.last).to(equal("var arrayVal;\(javaScriptString).then(function (listVal) {arrayVal = Array.from(listVal);});"))
                }

                describe("when a .javaScriptResultTypeIsUnsupported error comes from the webview") {
                    let wkError = WKError(_nsError: NSError(domain: "WKErrorDomain", code: 5))

                    describe("when provided a non-array value") {
                        beforeEach {
                            self.stubbedJSSingleSuper.observable = self.scheduler.createColdObservable([next(50, "purple")])
                                    .take(1)
                                    .asSingle()

                            self.stubbedJSSingleSuper.evaluateJSCompletion!(nil, wkError)
                            self.scheduler.start()
                        }

                        it("evaluates arrayval against the webview") {
                            expect(self.stubbedJSSingleSuper.evaluateJSSingleArgument).to(equal("arrayVal"))
                        }

                        it("pushes a valuenotarray error to the observer") {
                            let value = arrayObserver.events.first!.value
                            expect(value.error).to(matchError(WebViewError.ValueNotArray))
                            expect(value.element).to(beNil())
                        }
                    }

                    describe("when provided an array value") {
                        beforeEach {
                            self.stubbedJSSingleSuper.observable = self.scheduler.createColdObservable([next(50, ["purple"])])
                                    .take(1)
                                    .asSingle()

                            self.stubbedJSSingleSuper.evaluateJSCompletion!(nil, wkError)
                            self.scheduler.start()
                        }

                        it("evaluates arrayval against the webview") {
                            expect(self.stubbedJSSingleSuper.evaluateJSSingleArgument).to(equal("arrayVal"))
                        }

                        it("pushes the array to the observer") {
                            let value = arrayObserver.events.first!.value
                            expect(value.error).to(beNil())
                            expect(value.element as? [String]).to(equal(["purple"]))
                        }
                    }
                }

                describe("when a different wkerror error comes from the webview") {
                    let error = WKError(_nsError: NSError(domain: "WKErrorDomain", code: 3))
                    beforeEach {
                        self.stubbedJSSingleSuper.evaluateJSCompletion!(nil, error)
                    }

                    it("pushes the error to the observer") {
                        expect(arrayObserver.events.first!.value.error).to(matchError(error))
                        expect(arrayObserver.events.first!.value.element).to(beNil())
                    }
                }

                describe("when a non-wkerror error comes from the webview") {
                    let error = NSError(domain: "something", code: -1)
                    beforeEach {
                        self.stubbedJSSingleSuper.evaluateJSCompletion!(nil, error)
                    }

                    it("pushes the error to the observer") {
                        expect(arrayObserver.events.first!.value.error).to(matchError(error))
                        expect(arrayObserver.events.first!.value.element).to(beNil())
                    }
                }
            }
        }
    }
}

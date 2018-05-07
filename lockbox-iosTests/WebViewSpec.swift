/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import WebKit
import RxTest
import RxSwift
import RxBlocking

@testable import Lockbox

class WebViewSpec: QuickSpec {
    class StubbedEvaluateJSWebView: WebView {
        var evaluateJSArguments: [String] = []
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
        xdescribe("WebView") {
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

                describe("when provided an unsupported type webkit error") {
                    let wkError = WKError(_nsError: NSError(domain: "WKErrorDomain", code: 5))
                    beforeEach {
                        expect(self.stubbedJSSuper.evaluateJSArguments.last).toEventually(equal(javaScriptString))
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
                        expect(self.stubbedJSSuper.evaluateJSArguments.last).toEventually(equal(javaScriptString))
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
                        expect(self.stubbedJSSuper.evaluateJSArguments.last).toEventually(equal(javaScriptString))
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
                        expect(self.stubbedJSSuper.evaluateJSArguments.last).toEventually(equal(javaScriptString))
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
                        expect(self.stubbedJSSuper.evaluateJSArguments.last).toEventually(equal(javaScriptString))
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
        }
    }
}

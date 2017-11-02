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
    class StubbedEvaluateJSSingleWebView: WebView {
        var evaluateJSCalled: Bool = false
        var evaluateJSArgument: String?
        var firstObservable: Single<Any>?
        var secondObservable: Single<Any>?
        private var called = 0

        override func evaluateJavaScript(_ javaScriptString: String) -> Single<Any> {
            self.evaluateJSCalled = true
            self.evaluateJSArgument = javaScriptString
            called += 1
            return (called == 1) ? firstObservable! : secondObservable!
        }
    }

    var stubbedJSSingleSuper: StubbedEvaluateJSSingleWebView!
    var subject: WebView!
    var scheduler = TestScheduler(initialClock: 0)
    let disposeBag = DisposeBag()

    override func spec() {
        describe("WebView") {
            let javaScriptString = "console.log(butts)"

            describe(".evaluateJavaScriptToBool(javaScriptString:)") {
                var boolObserver = self.scheduler.createObserver(Bool.self)

                beforeEach {
                    self.stubbedJSSingleSuper = StubbedEvaluateJSSingleWebView()
                    self.subject = self.stubbedJSSingleSuper
                    boolObserver = self.scheduler.createObserver(Bool.self)
                }

                describe("when provided a bool value") {
                    beforeEach {
                        self.stubbedJSSingleSuper.firstObservable = self.scheduler.createHotObservable([next(50, true)])
                                .take(1)
                                .asSingle()

                        self.subject.evaluateJavaScriptToBool(javaScriptString)
                                .asObservable()
                                .subscribe(boolObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedJSSingleSuper.evaluateJSCalled).to(beTrue())
                        expect(self.stubbedJSSingleSuper.evaluateJSArgument).to(equal(javaScriptString))
                    }

                    it("pushes the boolean value out to the single with no error") {
                        let value = boolObserver.events.first!.value
                        expect(value.element).to(beTrue())
                        expect(value.error).to(beNil())
                    }
                }

                describe("when provided a non-bool value") {
                    beforeEach {
                        self.stubbedJSSingleSuper.firstObservable = self.scheduler.createHotObservable([next(100, "blarg")])
                                .take(1)
                                .asSingle()
                        self.subject.evaluateJavaScriptToBool(javaScriptString)
                                .asObservable()
                                .subscribe(boolObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedJSSingleSuper.evaluateJSCalled).to(beTrue())
                        expect(self.stubbedJSSingleSuper.evaluateJSArgument).to(equal(javaScriptString))
                    }

                    it("pushes the a no bool error out to the single with no value") {
                        let value = boolObserver.events.first!.value
                        expect(value.element).to(beNil())
                        expect(value.error).to(matchError(WebViewError.ValueNotBool))
                    }
                }
            }

            describe(".evaluateJavaScriptToString(javaScriptString:)") {
                var stringObserver = self.scheduler.createObserver(String.self)

                beforeEach {
                    self.stubbedJSSingleSuper = StubbedEvaluateJSSingleWebView()
                    self.subject = self.stubbedJSSingleSuper
                    stringObserver = self.scheduler.createObserver(String.self)
                }

                describe("when provided a string value") {
                    beforeEach {
                        self.stubbedJSSingleSuper.firstObservable = self.scheduler.createHotObservable([next(50, "purple")])
                                .take(1)
                                .asSingle()

                        self.subject.evaluateJavaScriptToString(javaScriptString)
                                .asObservable()
                                .subscribe(stringObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedJSSingleSuper.evaluateJSCalled).to(beTrue())
                        expect(self.stubbedJSSingleSuper.evaluateJSArgument).to(equal(javaScriptString))
                    }

                    it("pushes the string value out to the single with no error") {
                        let value = stringObserver.events.first!.value
                        expect(value.element).to(equal("purple"))
                        expect(value.error).to(beNil())
                    }
                }

                describe("when provided a non-string value") {
                    beforeEach {
                        self.stubbedJSSingleSuper.firstObservable = self.scheduler.createHotObservable([next(100, false)])
                                .take(1)
                                .asSingle()
                        self.subject.evaluateJavaScriptToString(javaScriptString)
                                .asObservable()
                                .subscribe(stringObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedJSSingleSuper.evaluateJSCalled).to(beTrue())
                        expect(self.stubbedJSSingleSuper.evaluateJSArgument).to(equal(javaScriptString))
                    }

                    it("pushes the no bool error out to the single with no value") {
                        let value = stringObserver.events.first!.value
                        expect(value.element).to(beNil())
                        expect(value.error).to(matchError(WebViewError.ValueNotString))
                    }
                }
            }

            xdescribe(".evaluateJavaScriptMapToArray()") {
                var arrayObserver: TestableObserver<[Any]>!

                beforeEach {
                    arrayObserver = self.scheduler.createObserver([Any].self)
                    self.stubbedJSSingleSuper = StubbedEvaluateJSSingleWebView()
                    self.subject = self.stubbedJSSingleSuper
                }

                describe("when a .javaScriptResultTypeIsUnsupported error comes from the webview") {
                    beforeEach {
                        // on hold until the scheduler can handle sending errors down the pipe
//                        self.stubbedJSSingleSuper.firstObservable = self.scheduler.createHotObservable([
//                                    next(100, WKError(_nsError: NSError(domain: "wkerror", code: 5)))
//                                ])
//                                .take(1)
//                                .asSingle()
                        self.subject.evaluateJavaScriptMapToArray(javaScriptString)
                                .asObservable()
                                .subscribe(arrayObserver)
                                .disposed(by: self.disposeBag)
                    }

                    it("evaluates the expanded js string with the passed parameter") {
                        expect(self.stubbedJSSingleSuper.evaluateJSCalled).to(beTrue())
                        expect(self.stubbedJSSingleSuper.evaluateJSArgument).to(equal("var arrayVal;\(javaScriptString).then(function (listVal) {arrayVal = Array.from(listVal);});"))
                    }

                    describe("when the arrayName evaluation yields an array") {
                        beforeEach {
                            self.stubbedJSSingleSuper.secondObservable = self.scheduler.createHotObservable([next(300, ["bumps"])])
                                    .take(1)
                                    .asSingle()
                            self.scheduler.start()
                        }

                        it("pushes the array to the observer with no error") {
                            let array = arrayObserver.events.first!.value.element as? [String]
                            expect(array).to(equal(["bumps"]))
                            expect(arrayObserver.events.first!.value.error).to(beNil())
                        }
                    }

                    describe("when the arrayName evaluation yields a different object") {
                        beforeEach {
                            self.stubbedJSSingleSuper.secondObservable = self.scheduler.createHotObservable([next(300, false)])
                                    .take(1)
                                    .asSingle()
                            self.scheduler.start()
                        }

                        it("pushes the array to the observer with no error") {
                            expect(arrayObserver.events.first!.value.element).to(beNil())
                            expect(arrayObserver.events.first!.value.error).to(matchError(WebViewError.ValueNotArray))
                        }

                    }
                }
            }
        }
    }
}

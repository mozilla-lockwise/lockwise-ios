import Quick
import Nimble
import WebKit
import RxTest
import RxSwift
import RxBlocking

@testable import lockbox_ios

class WebViewSpec: QuickSpec {
    class StubbedEvaluateWebview: WebView {
        var evaluateJSCalled: Bool = false
        var evaluateJSArgument: String?
        var evaluateJSCompletionHandler: ((Any?, Error?) -> Void)?
        var observable: Single<Any>?

        override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
            self.evaluateJSCalled = true
            self.evaluateJSArgument = javaScriptString
            self.evaluateJSCompletionHandler = completionHandler
        }

        override func evaluateJavaScript(_ javaScriptString: String) -> Single<Any> {
            self.evaluateJSCalled = true
            self.evaluateJSArgument = javaScriptString
            return observable!
        }
    }

    var stubbedSuper: StubbedEvaluateWebview!
    var subject: WebView!
    var scheduler = TestScheduler(initialClock: 0)
    let disposeBag = DisposeBag()

    override func spec() {
        beforeEach {
            self.stubbedSuper = StubbedEvaluateWebview()
            self.subject = self.stubbedSuper
        }

        describe("WebView") {
            let javaScriptString = "console.log(butts)"

            describe(".evaluateJavaScriptToBool(javaScriptString:)") {
                var boolObserver = self.scheduler.createObserver(Bool.self)

                beforeEach {
                    boolObserver = self.scheduler.createObserver(Bool.self)
                }

                describe("when provided a bool value") {
                    beforeEach {
                        self.stubbedSuper.observable = self.scheduler.createHotObservable([next(50, true)])
                                .take(1)
                                .asSingle()

                        self.subject.evaluateJavaScriptToBool(javaScriptString)
                                .asObservable()
                                .subscribe(boolObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedSuper.evaluateJSCalled).to(beTrue())
                        expect(self.stubbedSuper.evaluateJSArgument).to(equal(javaScriptString))
                    }

                    it("pushes the boolean value out to the single with no error") {
                        let value = boolObserver.events.first!.value
                        expect(value.element).to(beTrue())
                        expect(value.error).to(beNil())
                    }
                }

                describe("when provided a non-bool value") {
                    beforeEach {
                        self.stubbedSuper.observable = self.scheduler.createHotObservable([next(100, "blarg")])
                                .take(1)
                                .asSingle()
                        self.subject.evaluateJavaScriptToBool(javaScriptString)
                                .asObservable()
                                .subscribe(boolObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedSuper.evaluateJSCalled).to(beTrue())
                        expect(self.stubbedSuper.evaluateJSArgument).to(equal(javaScriptString))
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
                    stringObserver = self.scheduler.createObserver(String.self)
                }

                describe("when provided a string value") {
                    beforeEach {
                        self.stubbedSuper.observable = self.scheduler.createHotObservable([next(50, "purple")])
                                .take(1)
                                .asSingle()

                        self.subject.evaluateJavaScriptToString(javaScriptString)
                                .asObservable()
                                .subscribe(stringObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedSuper.evaluateJSCalled).to(beTrue())
                        expect(self.stubbedSuper.evaluateJSArgument).to(equal(javaScriptString))
                    }

                    it("pushes the string value out to the single with no error") {
                        let value = stringObserver.events.first!.value
                        expect(value.element).to(equal("purple"))
                        expect(value.error).to(beNil())
                    }
                }

                describe("when provided a non-string value") {
                    beforeEach {
                        self.stubbedSuper.observable = self.scheduler.createHotObservable([next(100, false)])
                                .take(1)
                                .asSingle()
                        self.subject.evaluateJavaScriptToString(javaScriptString)
                                .asObservable()
                                .subscribe(stringObserver)
                                .disposed(by: self.disposeBag)
                        self.scheduler.start()
                    }

                    it("passes the javascript to regular evaluation") {
                        expect(self.stubbedSuper.evaluateJSCalled).to(beTrue())
                        expect(self.stubbedSuper.evaluateJSArgument).to(equal(javaScriptString))
                    }

                    it("pushes the a no bool error out to the single with no value") {
                        let value = stringObserver.events.first!.value
                        expect(value.element).to(beNil())
                        expect(value.error).to(matchError(WebViewError.ValueNotString))
                    }
                }
            }

            describe(".evaluateJavaScriptMapToArray") {

            }
        }
    }
}

import Quick
import Nimble
import WebKit

@testable import lockbox_ios

class WebViewSpec : QuickSpec {
    class StubbedEvaluateWebview : WebView {
        var evaluateJSCalled:Bool = false
        var evaluateJSArgument:String?
        
        var evaluteJSCompletionHandler:((Any?, Error?) -> Void)?
        
        override func evaluateJavaScript(_ javaScriptString: String, completionHandler: ((Any?, Error?) -> Void)? = nil) {
            self.evaluateJSCalled = true
            self.evaluateJSArgument = javaScriptString
            self.evaluteJSCompletionHandler = completionHandler
        }
    }
    
    var stubbedSuper:StubbedEvaluateWebview!
    var subject:WebView!
    
    override func spec() {
        beforeEach {
            self.stubbedSuper = StubbedEvaluateWebview()
            self.subject = self.stubbedSuper
        }
        
        describe("WebView") {
            let javaScriptString = "console.log(butts)"
            
            describe(".evaluateJavaScriptToBool(javaScriptString:, completionHandler:)") {
                var evaluatedValue:Bool?
                var evaluatedError:Error?
                let error = NSError(domain: "domain", code: -1, userInfo: nil)
                
                beforeEach {
                    self.subject.evaluateJavaScriptToBool(javaScriptString, completionHandler: { (value, error) in
                        evaluatedValue = value
                        evaluatedError = error
                    })
                }
                
                it("evaluates the passed js string using the super method") {
                    expect(self.stubbedSuper.evaluateJSCalled).to(beTrue())
                    expect(self.stubbedSuper.evaluateJSArgument).to(equal(javaScriptString))
                }
                
                describe("when completion handler called with an error & no value") {
                    beforeEach {
                        self.stubbedSuper.evaluteJSCompletionHandler!(nil, error)
                    }
                    
                    it("calls the passed completion handler with the error") {
                        expect(evaluatedValue).to(beNil())
                        expect(evaluatedError).to(matchError(error))
                    }
                }
                
                describe("when completion handler called with an error & a value") {
                    beforeEach {
                        self.stubbedSuper.evaluteJSCompletionHandler!(false, error)
                    }
                    
                    it("calls the passed completion handler with the error & no value") {
                        expect(evaluatedValue).to(beNil())
                        expect(evaluatedError).to(matchError(error))
                    }
                }
                
                describe("when completion handler called with no error & a non-boolean value") {
                    beforeEach {
                        self.stubbedSuper.evaluteJSCompletionHandler!("bad string!", nil)
                    }
                    
                    it("calls the passed completion handler with the error & no value") {
                        expect(evaluatedValue).to(beNil())
                        expect(evaluatedError).to(beNil())
                    }
                }
                
                describe("when completion handler called with no error & a boolean value") {
                    let boolValue = true
                    beforeEach {
                        self.stubbedSuper.evaluteJSCompletionHandler!(boolValue, nil)
                    }
                    
                    it("calls the passed completion handler with no error & the value") {
                        expect(evaluatedValue).to(equal(boolValue))
                        expect(evaluatedError).to(beNil())
                    }
                }
            }
            
            describe(".evaluateJavaScriptToString(javaScriptString:, completionHandler:)") {
                var evaluatedValue:String?
                var evaluatedError:Error?
                let error = NSError(domain: "domain", code: -1, userInfo: nil)
                
                beforeEach {
                    self.subject.evaluateJavaScriptToString(javaScriptString, completionHandler: { (value, error) in
                        evaluatedValue = value
                        evaluatedError = error
                    })
                }
                
                it("evaluates the passed js string using the super method") {
                    expect(self.stubbedSuper.evaluateJSCalled).to(beTrue())
                    expect(self.stubbedSuper.evaluateJSArgument).to(equal(javaScriptString))
                }
                
                describe("when completion handler called with an error & no value") {
                    beforeEach {
                        self.stubbedSuper.evaluteJSCompletionHandler!(nil, error)
                    }
                    
                    it("calls the passed completion handler with the error") {
                        expect(evaluatedValue).to(beNil())
                        expect(evaluatedError).to(matchError(error))
                    }
                }
                
                describe("when completion handler called with an error & a value") {
                    beforeEach {
                        self.stubbedSuper.evaluteJSCompletionHandler!("false", error)
                    }
                    
                    it("calls the passed completion handler with the error & no value") {
                        expect(evaluatedValue).to(beNil())
                        expect(evaluatedError).to(matchError(error))
                    }
                }
                
                describe("when completion handler called with no error & a non-string value") {
                    beforeEach {
                        self.stubbedSuper.evaluteJSCompletionHandler!(false, nil)
                    }
                    
                    it("calls the passed completion handler with the error & no value") {
                        expect(evaluatedValue).to(beNil())
                        expect(evaluatedError).to(beNil())
                    }
                }
                
                describe("when completion handler called with no error & a string value") {
                    let stringValue = "sup dawg"
                    beforeEach {
                        self.stubbedSuper.evaluteJSCompletionHandler!(stringValue, nil)
                    }
                    
                    it("calls the passed completion handler with no error & the value") {
                        expect(evaluatedValue).to(equal(stringValue))
                        expect(evaluatedError).to(beNil())
                    }
                }
            }
        }
    }
}

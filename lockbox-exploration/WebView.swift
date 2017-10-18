import Foundation
import WebKit

//todo: figure out custom errors for these methods!

class WebView : WKWebView {
    func evaluateJavaScriptToBool(_ javaScriptString: String, completionHandler: ((Bool?, Error?) -> Void)? = nil) {
        self.evaluateJavaScript(javaScriptString) { (value, error) in
            if error != nil {
                completionHandler?(nil, error)
                return
            }
            
            if let boolValue = value as? Bool {
                completionHandler?(boolValue, error)
                return
            }
            
            completionHandler?(nil, error)
        }
    }
    
    func evaluateJavaScriptToString(_ javaScriptString: String, completionHandler: ((String?, Error?) -> Void)? = nil) {
        self.evaluateJavaScript(javaScriptString) { (value, error) in
            if error != nil {
                completionHandler?(nil, error)
                return
            }
            
            if let stringValue = value as? String {
                completionHandler?(stringValue, error)
                return
            }
            
            completionHandler?(nil, error)
        }
    }
    
    func evaluateJavaScriptMapToArray(_ javaScriptString: String, completionHandler: (([Any]?, Error?) -> Void)? = nil) {
        let arrayName = "arrayVal"
        
        self.evaluateJavaScript("var \(arrayName);\(javaScriptString).then(function (listVal) {\(arrayName) = Array.from(listVal);});") { (value, error) in
            if let wkError = error as? WKError {
                if wkError.code == .javaScriptResultTypeIsUnsupported {
                    self.evaluateJavaScript("\(arrayName)", completionHandler: { (value, error) in
                        if let arrayValue = value as? [Any] {
                            completionHandler?(arrayValue, error)
                            return
                        }
                    })
                    
                    return
                } else {
                    print("error: \(error!)")
                    completionHandler?(nil, error)
                    return
                }
            }
            
            completionHandler?(nil, error)
        }
    }
}

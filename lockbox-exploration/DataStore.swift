import Foundation
import WebKit

class DataStore : NSObject, WKNavigationDelegate, WKUIDelegate {
    var webView:WebView
    private let dataStoreName = "ds"
    
    init(webview:WebView!) {
        self.webView = webview
        super.init()
        
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        
        let baseUrl = URL(string: "file://\(Bundle.main.bundlePath)/lockbox-datastore/")!
        let path = "file://\(Bundle.main.bundlePath)/lockbox-datastore/index.html"
        
        self.webView.loadFileURL(URL(string:path)!, allowingReadAccessTo: baseUrl)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.evaluateJavaScript("var \(self.dataStoreName);DataStoreModule.open().then((function (datastore) {\(self.dataStoreName) = datastore;}));")
    }
    
    func initialized(completionHandler: ((Bool) -> Void)?) {
        self.webView.evaluateJavaScriptToBool("\(self.dataStoreName).initialized") { (value, error) in
            if value != nil {
                completionHandler?(value!)
                return
            }
            
            completionHandler?(false)
        }
    }
    
    func initialize(password:String) {
        self.webView.evaluateJavaScript("\(self.dataStoreName).initialize({password:\"\(password)\",})")
    }
    
    func locked(completionHandler: ((Bool) -> Void)?) {
        self.webView.evaluateJavaScriptToBool("\(self.dataStoreName).locked") { (value, error) in
            if value != nil {
                completionHandler?(value!)
            }
        }
    }
    
    func unlock(password:String) {
        self.webView.evaluateJavaScript("\(self.dataStoreName).unlock(\"\(password)\")")
    }
    
    func lock() {
        self.webView.evaluateJavaScript("\(self.dataStoreName).lock()")
    }
    
    func keyList(completionHandler: (([Any]) -> Void)?) {
        self.webView.evaluateJavaScriptMapToArray("\(self.dataStoreName).list()") { (array, error) in
            if array != nil {
                completionHandler?(array!)
            }
        }
    }
}

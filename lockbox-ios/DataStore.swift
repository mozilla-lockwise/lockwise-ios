import Foundation
import WebKit

enum DataStoreError : Error {
    case NoIDPassed
}

class DataStore : NSObject, WKNavigationDelegate {
    var webView:(WKWebView & TypedJavaScriptWebView)!
    private let dataStoreName:String!

    init<T: WKWebView>(webview: T, dataStoreName:String = "ds") where T: TypedJavaScriptWebView {
        self.webView = webview
        self.dataStoreName = dataStoreName
        super.init()

        self.webView.navigationDelegate = self

        let baseUrl = URL(string: "file://\(Bundle.main.bundlePath)/lockbox-datastore/")!
        let path = "file://\(Bundle.main.bundlePath)/lockbox-datastore/index.html"

        self.webView.loadFileURL(URL(string:path)!, allowingReadAccessTo: baseUrl)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.evaluateJavaScript("var \(self.dataStoreName!);DataStoreModule.open().then((function (datastore) {\(self.dataStoreName!) = datastore;}));")
    }

    func initialized(completionHandler: ((Bool) -> Void)?) {
        self.webView.evaluateJavaScriptToBool("\(self.dataStoreName!).initialized") { (value, error) in
            if value != nil {
                completionHandler?(value!)
                return
            }

            completionHandler?(false)
        }
    }

    func initialize(password:String) {
        self.webView.evaluateJavaScript("\(self.dataStoreName!).initialize({password:\"\(password)\",})")
    }

    func locked(completionHandler: ((Bool) -> Void)?) {
        self.webView.evaluateJavaScriptToBool("\(self.dataStoreName!).locked") { (value, error) in
            if value != nil {
                completionHandler?(value!)
                return
            }

            completionHandler?(false)
        }
    }

    func unlock(password:String) {
        self.webView.evaluateJavaScript("\(self.dataStoreName!).unlock(\"\(password)\")")
    }

    func lock() {
        self.webView.evaluateJavaScript("\(self.dataStoreName!).lock()")
    }

    func keyList(completionHandler: (([Item]) -> Void)?) {
        self.webView.evaluateJavaScriptMapToArray("\(self.dataStoreName!).list()") { (array, error) in
            let mappedArray = array?.map({ (value) -> Item in
                let itemDictionary = (value as! [Any])[1] as! [String:Any]
                return Parser.itemFromDictionary(itemDictionary)
            })

            completionHandler!(mappedArray!)
        }
    }

    func addItem(_ item:Item) {
        let jsonItem = Parser.jsonStringFromItem(item)

        self.webView.evaluateJavaScript("\(self.dataStoreName!).add(\(jsonItem))")
    }

    func deleteItem(_ item:Item) throws {
        if item.id == nil {
            throw DataStoreError.NoIDPassed
        }

        self.webView.evaluateJavaScript("\(self.dataStoreName!).delete(\"\(item.id!)\")")
    }

    func updateItem(_ item:Item) throws {
        if item.id == nil {
            throw DataStoreError.NoIDPassed
        }
        let jsonItem = Parser.jsonStringFromItem(item)

        self.webView.evaluateJavaScript("\(self.dataStoreName!).update(\(jsonItem))")
    }
}

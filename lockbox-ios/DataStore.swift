import Foundation
import WebKit
import RxSwift

enum DataStoreError : Error {
    case NoIDPassed, DataStoreLocked, DataStoreNotInitialized
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
        self.webView.evaluateJavaScript("var \(self.dataStoreName!);DataStoreModule.open().then((function (datastore) {\(self.dataStoreName!) = datastore;}));").map { $0 }
    }

    func initialized() -> Single<Bool> {
        return self.webView.evaluateJavaScriptToBool("\(self.dataStoreName!).initialized")
    }

    func initialize(password:String) {
        self.webView.evaluateJavaScript("\(self.dataStoreName!).initialize({password:\"\(password)\",})").map { $0 }
    }

    func locked() -> Single<Bool> {
        return self.webView.evaluateJavaScriptToBool("\(self.dataStoreName!).locked")
    }

    func unlock(password:String) {
        self.webView.evaluateJavaScript("\(self.dataStoreName!).unlock(\"\(password)\")").map { $0 }
    }

    func lock() {
        self.webView.evaluateJavaScript("\(self.dataStoreName!).lock()").map { $0 }
    }

    func keyList() -> Single<[Any]> {
        return self.webView.evaluateJavaScriptMapToArray("\(self.dataStoreName!).list()")
    }

    func addItem(_ item:Item) {
        let jsonItem = Parser.jsonStringFromItem(item)

        self.webView.evaluateJavaScript("\(self.dataStoreName!).add(\(jsonItem))").map { $0 }
    }

    func deleteItem(_ item:Item) throws {
        if item.id == nil {
            throw DataStoreError.NoIDPassed
        }

        self.webView.evaluateJavaScript("\(self.dataStoreName!).delete(\"\(item.id!)\")").map { $0 }
    }

    func updateItem(_ item:Item) throws {
        if item.id == nil {
            throw DataStoreError.NoIDPassed
        }
        let jsonItem = Parser.jsonStringFromItem(item)

        self.webView.evaluateJavaScript("\(self.dataStoreName!).update(\(jsonItem))").map { $0 }
    }
}

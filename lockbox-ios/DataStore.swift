import Foundation
import WebKit
import RxSwift

enum DataStoreError : Error {
    case NoIDPassed, DataStoreLocked, DataStoreNotInitialized, Unknown
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
        let _ = self.open().subscribe()
    }

    func open() -> Completable {
        return self.webView.evaluateJavaScript("var \(self.dataStoreName!);DataStoreModule.open().then((function (datastore) {\(self.dataStoreName!) = datastore;}));")
    }

    func initialized() -> Single<Bool> {
        return self.webView.evaluateJavaScriptToBool("\(self.dataStoreName!).initialized")
    }

    func initialize(password:String) -> Completable {
        return self.webView.evaluateJavaScript("\(self.dataStoreName!).initialize({password:\"\(password)\",})")
    }

    func locked() -> Single<Bool> {
        return self.webView.evaluateJavaScriptToBool("\(self.dataStoreName!).locked")
    }

    func unlock(password:String) -> Completable {
        return self.webView.evaluateJavaScript("\(self.dataStoreName!).unlock(\"\(password)\")")
    }

    func lock() -> Completable {
        return self.webView.evaluateJavaScript("\(self.dataStoreName!).lock()")
    }

    func keyList() -> Single<[Any]> {
        return self.webView.evaluateJavaScriptMapToArray("\(self.dataStoreName!).list()")
    }

    func addItem(_ item:Item) -> Completable {
        do {
            let jsonItem = try Parser.jsonStringFromItem(item)
            return self.webView.evaluateJavaScript("\(self.dataStoreName!).add(\(jsonItem))")
        } catch ParserError.InvalidItem {
            return Completable.error(ParserError.InvalidItem)
        } catch {
            return Completable.error(DataStoreError.Unknown)
        }
    }

    func deleteItem(_ item:Item) -> Completable {
        return self.webView.evaluateJavaScript("\(self.dataStoreName!).delete(\"\(item.id!)\")")
    }

    func updateItem(_ item:Item) -> Completable {
        do {
            let jsonItem = try Parser.jsonStringFromItem(item)

            return self.webView.evaluateJavaScript("\(self.dataStoreName!).update(\(jsonItem))")
        } catch ParserError.InvalidItem {
            return Completable.error(ParserError.InvalidItem)
        } catch {
            return Completable.error(DataStoreError.Unknown)
        }
    }
}

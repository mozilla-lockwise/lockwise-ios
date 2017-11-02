/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import RxSwift

enum DataStoreError: Error {
    case NoIDPassed, Locked, NotInitialized, Unknown
}

class DataStore: NSObject, WKNavigationDelegate {
    var webView: (WKWebView & TypedJavaScriptWebView)!
    private let dataStoreName: String!

    init<T:WKWebView>(webview: T, dataStoreName: String = "ds") where T: TypedJavaScriptWebView {
        self.webView = webview
        self.dataStoreName = dataStoreName
        super.init()

        self.webView.navigationDelegate = self

        let baseUrl = URL(string: "file://\(Bundle.main.bundlePath)/lockbox-datastore/")!
        let path = "file://\(Bundle.main.bundlePath)/lockbox-datastore/index.html"

        self.webView.loadFileURL(URL(string: path)!, allowingReadAccessTo: baseUrl)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let _ = self.open().subscribe()
    }

    func open() -> Single<Any> {
        return self.webView.evaluateJavaScript("var \(self.dataStoreName!);DataStoreModule.open().then((function (datastore) {\(self.dataStoreName!) = datastore;}));")
    }

    func initialized() -> Single<Bool> {
        return self.webView.evaluateJavaScriptToBool("\(self.dataStoreName!).initialized")
    }

    func initialize(password: String) -> Single<Any> {
        return self.webView.evaluateJavaScript("\(self.dataStoreName!).initialize({password:\"\(password)\",})")
    }

    func locked() -> Single<Bool> {
        return self.webView.evaluateJavaScriptToBool("\(self.dataStoreName!).locked")
    }

    func unlock(password: String) -> Single<Any> {
        return self.webView.evaluateJavaScript("\(self.dataStoreName!).unlock(\"\(password)\")")
    }

    func lock() -> Single<Any> {
        return self.webView.evaluateJavaScript("\(self.dataStoreName!).lock()")
    }

    func list() -> Single<[Any]> {
        return checkState().flatMap { _ in
            return self.webView.evaluateJavaScriptMapToArray("\(self.dataStoreName!).list()")
        }
    }

    func getItem(_ id:String) -> Single<Item> {
        return checkState().flatMap { _ in
            return self.webView.evaluateJavaScript("\(self.dataStoreName!).get(\"\(id)\")")
        }.map { value -> Item in
            return try Parser.itemFromDictionary(value as! [String:Any])
        }
    }

    func addItem(_ item: Item) -> Single<Any> {
        do {
            let jsonItem = try Parser.jsonStringFromItem(item)
            return checkState().flatMap { _ in
                return self.webView.evaluateJavaScript("\(self.dataStoreName!).add(\(jsonItem))")
            }
        } catch ParserError.InvalidItem {
            return Single.error(ParserError.InvalidItem)
        } catch {
            return Single.error(DataStoreError.Unknown)
        }
    }

    func deleteItem(_ item: Item) -> Single<Any> {
        if item.id == nil {
            return Single.error(DataStoreError.NoIDPassed)
        }

        return checkState().flatMap { _ in
            return self.webView.evaluateJavaScript("\(self.dataStoreName!).delete(\"\(item.id!)\")")
        }
    }

    func updateItem(_ item: Item) -> Single<Any> {
        if item.id == nil {
            return Single.error(DataStoreError.NoIDPassed)
        }

        do {
            let jsonItem = try Parser.jsonStringFromItem(item)

            return checkState().flatMap { _ in
                return self.webView.evaluateJavaScript("\(self.dataStoreName!).update(\(jsonItem))")
            }
        } catch ParserError.InvalidItem {
            return Single.error(ParserError.InvalidItem)
        } catch {
            return Single.error(DataStoreError.Unknown)
        }
    }

    private func checkState() -> Single<Bool> {
        return initialized().asObservable()
                .flatMap { initialized -> Observable<Bool> in
                    if !initialized {
                        throw DataStoreError.NotInitialized
                    }

                    return self.locked().asObservable()
                }
                .map { locked -> Bool in
                    if locked {
                        throw DataStoreError.Locked
                    }

                    return locked
                }
                .asSingle()
    }
}

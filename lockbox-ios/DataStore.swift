/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import RxSwift

enum DataStoreError: Error {
    case NoIDPassed, Locked, NotInitialized, UnexpectedType, Unknown
}

class DataStore: NSObject, WKNavigationDelegate {
    var webView: (WKWebView & TypedJavaScriptWebView)!
    private let dataStoreName: String!
    private let parser:ItemParser!
    private let disposeBag = DisposeBag()

    init<T:WKWebView>(webview: T,
                      dataStoreName: String? = "ds",
                      parser:ItemParser? = Parser()) where T: TypedJavaScriptWebView {
        self.webView = webview
        self.dataStoreName = dataStoreName
        self.parser = parser
        super.init()

        self.webView.navigationDelegate = self

        let baseUrl = URL(string: "file://\(Bundle.main.bundlePath)/lockbox-datastore/")!
        let path = "file://\(Bundle.main.bundlePath)/lockbox-datastore/index.html"

        self.webView.loadFileURL(URL(string: path)!, allowingReadAccessTo: baseUrl)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let _ = self.open().subscribe().disposed(by: disposeBag)
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

    func list() -> Single<[Item]> {
        return checkState().flatMap { _ in
            return self.webView.evaluateJavaScriptMapToArray("\(self.dataStoreName!).list()")
                    .map { anyList -> [Item] in
                        return try anyList.map { value -> Item in
                            guard let itemDictionary = value as? [String: Any] else {
                                throw DataStoreError.UnexpectedType
                            }

                            return try self.parser.itemFromDictionary(itemDictionary)
                        }
                    }
        }
    }

    func getItem(_ id:String) -> Single<Item> {
        return checkState().flatMap { _ in
            return self.webView.evaluateJavaScript("\(self.dataStoreName!).get(\"\(id)\")")
        }.map { value -> Item in
            guard let itemDictionary = value as? [String: Any] else {
                throw DataStoreError.UnexpectedType
            }

            return try self.parser.itemFromDictionary(itemDictionary)
        }
    }

    func addItem(_ item: Item) -> Single<Any> {
        var jsonItem = ""
        do {
            jsonItem = try self.parser.jsonStringFromItem(item)
        } catch {
            return Single.error(error)
        }

        return checkState().flatMap { _ in
            return self.webView.evaluateJavaScript("\(self.dataStoreName!).add(\(jsonItem))")
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

        var jsonItem = ""
        do {
            jsonItem = try self.parser.jsonStringFromItem(item)
        } catch {
            return Single.error(error)
        }
        
        return checkState().flatMap { _ in
            return self.webView.evaluateJavaScript("\(self.dataStoreName!).update(\(jsonItem))")
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

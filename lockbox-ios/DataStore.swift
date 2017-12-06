/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import RxSwift

enum DataStoreError: Error {
    case NoIDPassed, Locked, NotInitialized, UnexpectedType, UnexpectedJavaScriptMethod, Unknown
}

enum JSCallbackFunction: String {
    case OpenComplete, InitializeComplete, UnlockComplete, LockComplete, ListComplete, GetComplete, AddComplete, UpdateComplete, DeleteComplete
}

class DataStore: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    internal var webView: (WKWebView & TypedJavaScriptWebView)!
    private let dataStoreName: String!
    private let parser:ItemParser!
    private let disposeBag = DisposeBag()

    // Subject references for .js calls
    private let openSubject = PublishSubject<Any>()
    private let initializeSubject = PublishSubject<Any>()
    private let unlockSubject = PublishSubject<Any>()
    private let lockSubject = ReplaySubject<Any>.create(bufferSize: 1)
    private let listSubject = PublishSubject<[Item]>()
    private let getSubject = PublishSubject<Item>()
    private let addSubject = PublishSubject<Item>()
    private let updateSubject = PublishSubject<Item>()
    private let deleteSubject = PublishSubject<Any>()

    private let loadedSubject = PublishSubject<Void>()

    internal var webViewConfiguration:WKWebViewConfiguration {
        get {
            let webConfig = WKWebViewConfiguration()

            webConfig.userContentController.add(self, name: JSCallbackFunction.OpenComplete.rawValue)
            webConfig.userContentController.add(self, name: JSCallbackFunction.InitializeComplete.rawValue)
            webConfig.userContentController.add(self, name: JSCallbackFunction.UnlockComplete.rawValue)
            webConfig.userContentController.add(self, name: JSCallbackFunction.LockComplete.rawValue)
            webConfig.userContentController.add(self, name: JSCallbackFunction.ListComplete.rawValue)
            webConfig.userContentController.add(self, name: JSCallbackFunction.GetComplete.rawValue)
            webConfig.userContentController.add(self, name: JSCallbackFunction.AddComplete.rawValue)
            webConfig.userContentController.add(self, name: JSCallbackFunction.UpdateComplete.rawValue)
            webConfig.userContentController.add(self, name: JSCallbackFunction.DeleteComplete.rawValue)

            webConfig.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
            webConfig.preferences.javaScriptEnabled = true

            return webConfig
        }
    }

    init(webView: inout WebView,
         dataStoreName: String? = "ds",
         parser:ItemParser? = Parser()) {
        self.dataStoreName = dataStoreName
        self.parser = parser
        super.init()

        webView = WebView(frame: .zero, configuration: self.webViewConfiguration)
        webView.navigationDelegate = self
        self.webView = webView

        let baseUrl = URL(string: "file://\(Bundle.main.bundlePath)/lockbox-datastore/")!
        let path = "file://\(Bundle.main.bundlePath)/lockbox-datastore/index.html"

        self.webView.loadFileURL(URL(string: path)!, allowingReadAccessTo: baseUrl)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.open()
                .subscribe()
                .disposed(by: disposeBag)

        self.loadedSubject.onNext(())
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let messageBody = message.body
        switch message.name {
        case JSCallbackFunction.OpenComplete.rawValue:
            self.openSubject.onNext(messageBody)
            break
        case JSCallbackFunction.InitializeComplete.rawValue:
            self.initializeSubject.onNext(messageBody)
            break
        case JSCallbackFunction.UnlockComplete.rawValue:
            self.unlockSubject.onNext(messageBody)
            break
        case JSCallbackFunction.LockComplete.rawValue:
            self.lockSubject.onNext(messageBody)
            break
        case JSCallbackFunction.DeleteComplete.rawValue:
            self.deleteSubject.onNext(messageBody)
            break
        case JSCallbackFunction.GetComplete.rawValue:
            completeSubjectWithBody(messageBody: messageBody, subject: self.getSubject)
            break
        case JSCallbackFunction.AddComplete.rawValue:
            completeSubjectWithBody(messageBody: messageBody, subject: self.addSubject)
            break
        case JSCallbackFunction.UpdateComplete.rawValue:
            completeSubjectWithBody(messageBody: messageBody, subject: self.updateSubject)
            break
        case JSCallbackFunction.ListComplete.rawValue:
            guard let listBody = messageBody as? [[Any]] else {
                self.listSubject.onError(DataStoreError.UnexpectedType)
                break
            }

            var itemList:[Item]
            do {
                itemList = try listBody.map { anyList -> Item in
                    guard let itemDictionary = anyList[1] as? [String: Any] else {
                        throw DataStoreError.UnexpectedType
                    }

                    return try self.parser.itemFromDictionary(itemDictionary)
                }
            } catch {
                self.listSubject.onError(error)
                break
            }

            self.listSubject.onNext(itemList)
            break
        default:
            openSubject.onError(DataStoreError.UnexpectedJavaScriptMethod)
            initializeSubject.onError(DataStoreError.UnexpectedJavaScriptMethod)
            unlockSubject.onError(DataStoreError.UnexpectedJavaScriptMethod)
            lockSubject.onError(DataStoreError.UnexpectedJavaScriptMethod)
            listSubject.onError(DataStoreError.UnexpectedJavaScriptMethod)
            getSubject.onError(DataStoreError.UnexpectedJavaScriptMethod)
            addSubject.onError(DataStoreError.UnexpectedJavaScriptMethod)
            updateSubject.onError(DataStoreError.UnexpectedJavaScriptMethod)
            deleteSubject.onError(DataStoreError.UnexpectedJavaScriptMethod)
            break
        }
    }

    func dataStoreLoaded() -> Observable<Void> {
        return self.loadedSubject.asObservable()
    }

    func open() -> Single<Any> {
        return self.webView.evaluateJavaScript("var \(self.dataStoreName!);swiftOpen().then(function (datastore) {\(self.dataStoreName!) = datastore;});")
                .flatMap { _ in
                    return self.openSubject.take(1).asSingle()
                }
    }

    func initialized() -> Single<Bool> {
        return self.webView.evaluateJavaScriptToBool("\(self.dataStoreName!).initialized")
    }

    func initialize(password: String) -> Single<Any> {
        return self.webView.evaluateJavaScript("\(self.dataStoreName!).initialize({\"password\":\"\(password)\"})")
                .flatMap { _ in
                    return self.initializeSubject.take(1).asSingle()
                }
    }

    func locked() -> Single<Bool> {
        return self.webView.evaluateJavaScriptToBool("\(self.dataStoreName!).locked")
    }

    func unlock(password: String) -> Single<Any> {
        return self.webView.evaluateJavaScript("\(self.dataStoreName!).unlock(\"\(password)\")")
                .flatMap { _ in
                    return self.unlockSubject.take(1).asSingle()
                }
    }

    func lock() -> Single<Any> {
        return self.webView.evaluateJavaScript("\(self.dataStoreName!).lock()")
                .flatMap { _ in
                    return self.lockSubject.take(1).asSingle()
                }
    }

    func list() -> Single<[Item]> {
        return checkState().flatMap { _ in
            return self.webView.evaluateJavaScript("\(self.dataStoreName!).list()")
        }.flatMap { _ in
            return self.listSubject.take(1).asSingle()
        }
    }

    func getItem(_ id:String) -> Single<Item> {
        return checkState().flatMap { _ in
            return self.webView.evaluateJavaScript("\(self.dataStoreName!).get(\"\(id)\")")
        }.flatMap { (any) -> Single<Item> in
            return self.getSubject.take(1).asSingle()
        }
    }

    func addItem(_ item: Item) -> Single<Item> {
        var jsonItem = ""
        do {
            jsonItem = try self.parser.jsonStringFromItem(item)
        } catch {
            return Single.error(error)
        }

        return checkState().flatMap { _ in
            return self.webView.evaluateJavaScript("\(self.dataStoreName!).add(\(jsonItem))")
        }.flatMap { _ in
            return self.addSubject.take(1).asSingle()
        }
    }

    func deleteItem(_ item: Item) -> Single<Any> {
        if item.id == nil {
            return Single.error(DataStoreError.NoIDPassed)
        }

        return checkState().flatMap { _ in
            return self.webView.evaluateJavaScript("\(self.dataStoreName!).remove(\"\(item.id!)\")")
        }.flatMap { _ in
            return self.deleteSubject.take(1).asSingle()
        }
    }

    func updateItem(_ item: Item) -> Single<Item> {
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
        }.flatMap { _ in
            return self.updateSubject.take(1).asSingle()
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

    private func completeSubjectWithBody(messageBody:Any, subject:PublishSubject<Item>) {
        guard let itemDictionary = messageBody as? [String:Any] else {
            subject.onError(DataStoreError.UnexpectedType)
            return
        }

        var item:Item
        do {
            item = try self.parser.itemFromDictionary(itemDictionary)
        } catch {
            subject.onError(error)
            return
        }

        subject.onNext(item)
    }
}

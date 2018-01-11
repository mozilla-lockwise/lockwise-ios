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
    case OpenComplete, InitializeComplete, UnlockComplete, LockComplete, ListComplete

    static let allValues:[JSCallbackFunction] = [.OpenComplete, .InitializeComplete, .UnlockComplete, .LockComplete, .ListComplete]
}

enum DataStoreAction: Action {
    case list(list: [Item])
    case locked(locked: Bool)
    case initialized(initialized: Bool)
}

extension DataStoreAction: Equatable {
    static func ==(lhs: DataStoreAction, rhs: DataStoreAction) -> Bool {
        switch (lhs, rhs) {
        case (.list(let lhList), .list(let rhList)):
            return lhList.elementsEqual(rhList)
        case (.locked(let lhLocked), .locked(let rhLocked)):
            return lhLocked == rhLocked
        case (.initialized(let lhInitialized), .initialized(let rhInitialized)):
            return lhInitialized == rhInitialized
        default:
            return false
        }
    }
}

class DataStoreActionHandler: NSObject, ActionHandler {
    static let shared = DataStoreActionHandler()
    private var dispatcher:Dispatcher

    internal var webView: (WKWebView & TypedJavaScriptWebView)!
    private let dataStoreName: String
    private let parser:ItemParser!
    private let disposeBag = DisposeBag()

    // Subject references for .js calls
    private var openSubject = ReplaySubject<Void>.create(bufferSize: 1)
    private var initializeSubject = PublishSubject<Void>()
    private var unlockSubject = PublishSubject<Void>()
    private var lockSubject = PublishSubject<Void>()
    private var listSubject = PublishSubject<[Item]>()

    internal var webViewConfiguration:WKWebViewConfiguration {
        get {
            let webConfig = WKWebViewConfiguration()

            for f in JSCallbackFunction.allValues {
                webConfig.userContentController.add(self, name: f.rawValue)
            }

            webConfig.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
            webConfig.preferences.javaScriptEnabled = true

            return webConfig
        }
    }

    init(dataStoreName: String = "ds",
         parser: ItemParser = Parser(),
         dispatcher: Dispatcher = Dispatcher.shared) {
        self.dataStoreName = dataStoreName
        self.parser = parser
        self.dispatcher = dispatcher
        super.init()

        self.webView = WebView(frame: .zero, configuration: self.webViewConfiguration)
        self.webView.navigationDelegate = self

        guard let baseUrl = URL(string: "file://\(Bundle.main.bundlePath)/lockbox-datastore/"),
              let path = URL(string: "file://\(Bundle.main.bundlePath)/lockbox-datastore/index.html") else {
            self.dispatcher.dispatch(action: ErrorAction(error: DataStoreError.Unknown))
            return
        }

        self.webView.loadFileURL(path, allowingReadAccessTo: baseUrl)
    }

    public func initialize(scopedKey: String, uid: String) {
        self.initializeSubject
                .take(1)
                .subscribe(onNext: { [weak self] _ in
                    self?.dispatcher.dispatch(action: DataStoreAction.initialized(initialized: true))
                }, onError: { [weak self] error in
                    self?.dispatcher.dispatch(action: ErrorAction(error: error))
                    self?.initializeSubject = PublishSubject<Void>()
                })
                .disposed(by: self.disposeBag)

        self._initialize(scopedKey: scopedKey, uid: uid)
    }

    public func updateInitialized() {
        self._initialized()
                .subscribe(onSuccess: { [weak self] initialized in
                    self?.dispatcher.dispatch(action: DataStoreAction.initialized(initialized: initialized))
                }, onError: { [weak self] error in
                    self?.dispatcher.dispatch(action: ErrorAction(error: error))
                })
                .disposed(by: self.disposeBag)
    }

    public func unlock(scopedKey: String) {
        self.unlockSubject
                .take(1)
                .subscribe(onNext: { [weak self] _ in
                    self?.dispatcher.dispatch(action: DataStoreAction.locked(locked: false))
                }, onError: { [weak self] error in
                    self?.dispatcher.dispatch(action: ErrorAction(error: error))
                    self?.unlockSubject = PublishSubject<Void>()
                })
                .disposed(by: self.disposeBag)

        self._unlock(scopedKey: scopedKey)
    }

    public func lock() {
        self.lockSubject
                .take(1)
                .subscribe(onNext: { [weak self] _ in
                    self?.dispatcher.dispatch(action: DataStoreAction.locked(locked: true))
                }, onError: { [weak self] error in
                    self?.dispatcher.dispatch(action: ErrorAction(error: error))
                    self?.lockSubject = PublishSubject<Void>()
                })
                .disposed(by: self.disposeBag)

        self._lock()
    }

    public func updateLocked() {
        self._locked()
                .subscribe(onSuccess: { [weak self] locked in
                    self?.dispatcher.dispatch(action: DataStoreAction.locked(locked: locked))
                }, onError: { [weak self] error in
                    self?.dispatcher.dispatch(action: ErrorAction(error: error))
                })
                .disposed(by: self.disposeBag)
    }

    public func list() {
        self.listSubject
                .take(1)
                .subscribe(onNext: { [weak self] itemList in
                    self?.dispatcher.dispatch(action: DataStoreAction.list(list: itemList))
                }, onError: { [weak self] error in
                    self?.dispatcher.dispatch(action: ErrorAction(error: error))
                    self?.listSubject = PublishSubject<[Item]>()
                })
                .disposed(by: self.disposeBag)

        self._list()
    }
}

// javascript interaction
extension DataStoreActionHandler {
    private func _open() -> Observable<Void> {
        return self.webView.evaluateJavaScript("var \(self.dataStoreName);swiftOpen().then(function (datastore) {\(self.dataStoreName) = datastore;});")
                .asObservable()
                .flatMap { _ in
                    self.openSubject.asObservable()
                }
    }

    private func _initialized() -> Single<Bool> {
        return self.openSubject
                .take(1)
                .asSingle()
                .flatMap { _ in
                    self.webView.evaluateJavaScriptToBool("\(self.dataStoreName).initialized")
                }
    }

    private func _initialize(scopedKey: String, uid: String) {
        self.openSubject
                .take(1)
                .flatMap { _ in
                    self.webView.evaluateJavaScript("\(self.dataStoreName).initialize({\"appKey\":\(scopedKey), \"salt\":\"\(uid)\"})")
                }
                .subscribe(onError:{ error in
                    self.initializeSubject.onError(error)
                })
                .disposed(by: self.disposeBag)
    }

    private func _locked() -> Single<Bool> {
        return self.openSubject
                .take(1)
                .asSingle()
                .flatMap { _ in
                    self.webView.evaluateJavaScriptToBool("\(self.dataStoreName).locked")
                }
    }

    private func _unlock(scopedKey: String) {
        self.openSubject
                .take(1)
                .flatMap { _ in
                    self.webView.evaluateJavaScript("\(self.dataStoreName).unlock(\(scopedKey))")
                }
                .subscribe(onError:{ error in
                    self.unlockSubject.onError(error)
                })
                .disposed(by: self.disposeBag)
    }

    private func _lock() {
        self.openSubject
                .take(1)
                .flatMap { _ in
                    self.webView.evaluateJavaScript("\(self.dataStoreName).lock()")
                }
                .subscribe(onError:{ error in
                    self.lockSubject.onError(error)
                })
                .disposed(by: self.disposeBag)
    }

    private func _list() {
        self.openSubject
                .take(1)
                .flatMap { _ in
                    self.checkState()
                }
                .flatMap { _ in
                    self.webView.evaluateJavaScript("\(self.dataStoreName).list()")
                }
                .subscribe(onError:{ error in
                    self.listSubject.onError(error)
                })
                .disposed(by: self.disposeBag)
    }

    private func checkState() -> Single<Bool> {
        return _initialized().asObservable()
                .flatMap { initialized -> Observable<Bool> in
                    if !initialized {
                        throw DataStoreError.NotInitialized
                    }

                    return self._locked().asObservable()
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

extension DataStoreActionHandler: WKScriptMessageHandler, WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self._open()
                .take(1)
                .subscribe(onError: { error in
                    self.dispatcher.dispatch(action: ErrorAction(error: error))
                    self.openSubject = ReplaySubject<Void>.create(bufferSize: 1)
                 })
                .disposed(by: self.disposeBag)
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let function = JSCallbackFunction.init(rawValue: message.name) else {
            self.dispatcher.dispatch(action: ErrorAction(error: DataStoreError.UnexpectedJavaScriptMethod))
            return
        }

        switch function {
        case .OpenComplete:
            self.openSubject.onNext(())
        case .InitializeComplete:
            self.initializeSubject.onNext(())
        case .UnlockComplete:
            self.unlockSubject.onNext(())
        case .LockComplete:
            self.lockSubject.onNext(())
        case .ListComplete:
            guard let listBody = message.body as? [[Any]] else {
                self.dispatcher.dispatch(action: ErrorAction(error: DataStoreError.UnexpectedType))
                break
            }

            let itemList = listBody.flatMap { (anyList: [Any]) -> Item? in
                guard let itemDictionary = anyList[1] as? [String: Any],
                      let item = try? self.parser.itemFromDictionary(itemDictionary) else {
                    return nil
                }

                return item
            }

            self.listSubject.onNext(itemList)
        }
    }
}

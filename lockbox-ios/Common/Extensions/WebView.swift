/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import RxSwift

enum WebViewError: Error {
    case ValueNotBool, ValueNotString, ValueNotArray, Unknown
}

protocol TypedJavaScriptWebView {
    func evaluateJavaScriptToBool(_ javaScriptString: String) -> Single<Bool>
    func evaluateJavaScript(_ javaScriptString: String) -> Single<Any>
}

class WebView: WKWebView, TypedJavaScriptWebView {
    public func evaluateJavaScriptToBool(_ javaScriptString: String) -> Single<Bool> {
        let boolSingle = self.evaluateJavaScript(javaScriptString)
                .map { value -> Bool in
                    guard let boolValue = value as? Bool else {
                        throw WebViewError.ValueNotBool
                    }

                    return boolValue
                }

        return boolSingle
    }

    public func evaluateJavaScript(_ javaScriptString: String) -> Single<Any> {
        let anySingle = self.evaluateJavaScriptWithoutCatchingInvalidType(javaScriptString)
                .catchError { error in
                    guard let wkError = error as? WKError,
                          wkError.code.rawValue == WKError.javaScriptResultTypeIsUnsupported.rawValue else {
                        throw error
                    }

                    return Single.just("")
                }

        return anySingle
    }

    internal func evaluateJavaScriptWithoutCatchingInvalidType(_ javaScriptString: String) -> Single<Any> {
        let anySingle = Single<Any>.create { single in

            DispatchQueue.main.async {
                self.evaluateJavaScript(javaScriptString) { any, error in
                    if error != nil {
                        single(.error(error!))
                    } else if any != nil {
                        single(.success(any!))
                    } else {
                        single(.error(WebViewError.Unknown))
                    }
                }
            }

            return Disposables.create()
        }

        return anySingle
    }
}

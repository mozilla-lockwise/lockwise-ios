import Foundation
import WebKit
import RxSwift

enum WebViewError: Error {
    case ValueNotBool, ValueNotString, ValueNotArray, Unknown
}

protocol TypedJavaScriptWebView {
    func evaluateJavaScriptToBool(_ javaScriptString: String) -> Single<Bool>
    func evaluateJavaScriptToString(_ javaScriptString: String) -> Single<String>
    func evaluateJavaScriptMapToArray(_ javaScriptString: String) -> Single<[Any]>
    func evaluateJavaScript(_ javaScriptString: String) -> Single<Any>
}

class WebView: WKWebView, TypedJavaScriptWebView {
    func evaluateJavaScriptToBool(_ javaScriptString: String) -> Single<Bool> {
        return self.evaluateJavaScript(javaScriptString)
                .map { value -> Bool in
                    if let boolValue = value as? Bool {
                        return boolValue
                    } else {
                        throw WebViewError.ValueNotBool
                    }
                }
    }

    func evaluateJavaScriptToString(_ javaScriptString: String) -> Single<String> {
        return self.evaluateJavaScript(javaScriptString)
                .map { value -> String in
                    if let stringValue = value as? String {
                        return stringValue
                    } else {
                        throw WebViewError.ValueNotString
                    }
                }
    }

    func evaluateJavaScriptMapToArray(_ javaScriptString: String) -> Single<[Any]> {
        let arrayName = "arrayVal"

        return self.evaluateJavaScriptWithoutCatchingInvalidType("var \(arrayName);\(javaScriptString).then(function (listVal) {\(arrayName) = Array.from(listVal);});")
                .map {
                    $0
                } // resolve overloaded function name
                .asObservable()
                .catchError { error in
                    if let wkError = error as? WKError {
                        if wkError.code == .javaScriptResultTypeIsUnsupported {
                            return self.evaluateJavaScript("\(arrayName)").asObservable()
                        }
                    }

                    throw error
                }
                .asSingle()
                .map { any -> [Any] in
                    if let arrayVal = any as? [Any] {
                        return arrayVal
                    } else {
                        throw WebViewError.ValueNotArray
                    }
                }
    }

    func evaluateJavaScript(_ javaScriptString: String) -> Single<Any> {
        return Single<Any>.create() { single in

            super.evaluateJavaScript(javaScriptString) { any, error in
                if let wkError = error as? WKError {
                    if wkError.code == .javaScriptResultTypeIsUnsupported {
                        single(.success(""))
                        return
                    }
                } else if error != nil {
                    single(.error(error!))
                    return
                } else if any != nil {
                    single(.success(any!))
                    return
                } else {
                    single(.error(WebViewError.Unknown))
                }
            }

            return Disposables.create()
        }
    }

    private func evaluateJavaScriptWithoutCatchingInvalidType(_ javaScriptString: String) -> Single<Any> {
        return Single<Any>.create() { single in

            super.evaluateJavaScript(javaScriptString) { any, error in
                if error != nil {
                    single(.error(error!))
                } else if any != nil {
                    single(.success(any!))
                } else {
                    single(.error(WebViewError.Unknown))
                }
            }

            return Disposables.create()
        }
    }
}

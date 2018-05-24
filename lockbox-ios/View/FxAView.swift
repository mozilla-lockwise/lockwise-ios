/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON

class FxAView: UIViewController, FxAViewProtocol, WKNavigationDelegate {
    internal var presenter: FxAPresenter?
    private var webView: WKWebView
    private var disposeBag = DisposeBag()
    private var url: URL?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    init(webView: WKWebView = WKWebView()) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
        self.presenter = FxAPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureWebView()
        self.webView.navigationDelegate = self
        self.view = self.webView
        self.setupNavBar()

        self.presenter?.onViewReady()
    }

    func loadRequest(_ urlRequest: URLRequest) {
        self.webView.load(urlRequest)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if self.url == nil {
            self.url = webView.url
        }
    }
}

private enum RemoteCommand: String {
    case canLinkAccount = "can_link_account"
    case loaded = "loaded"
    case login = "login"
    case sessionStatus = "session_status"
    case signOut = "sign_out"
}

extension FxAView: WKScriptMessageHandler {
    func configureWebView() {
        guard let source = getJS() else {
            fatalError("Can't find JS from bundle")
        }
        let userScript = WKUserScript(
            source: source,
            injectionTime: WKUserScriptInjectionTime.atDocumentEnd,
            forMainFrameOnly: true
        )

        // Handle messages from the content server (via our user script).
        let contentController = webView.configuration.userContentController
        contentController.addUserScript(userScript)
        contentController.add(LeakAvoider(delegate: self), name: "accountsCommandHandler")
    }

    fileprivate func getJS() -> String? {
        let fileRoot = Bundle.main.path(forResource: "FxASignIn", ofType: "js")
        return (try? NSString(contentsOfFile: fileRoot!, encoding: String.Encoding.utf8.rawValue)) as String?
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // Make sure we're communicating with a trusted page. That is, ensure the origin of the
        // message is the same as the origin of the URL we initially loaded in this web view.
        // Note that this exploit wouldn't be possible if we were using WebChannels; see
        // https://developer.mozilla.org/en-US/docs/Mozilla/JavaScript_code_modules/WebChannel.jsm
        let origin = message.frameInfo.securityOrigin
        guard let url = self.url,
              origin.`protocol` == url.scheme,
              origin.host == url.host,
              origin.port == (url.port ?? 0) else {
            print("Ignoring message - \(origin) does not match expected origin \(self.url?.origin)")
            return
        }

        if message.name == "accountsCommandHandler" {
            let body = JSON(message.body)
            let detail = body["detail"]
            handleRemoteCommand(detail["command"].stringValue, data: detail["data"])
        }
    }

    // Handle a message coming from the content server.
    func handleRemoteCommand(_ rawValue: String, data: JSON) {
        if let command = RemoteCommand(rawValue: rawValue) {
            switch command {
            case .loaded:
                print("loaded")
            case .login:
                print("login")
                onLogin(data)
            case .canLinkAccount:
                onCanLinkAccount(data)
            case .sessionStatus:
                print("sessionStatus")
            case .signOut:
                print("signout")
            }
        }
    }

    func onLogin(_ data: JSON) {
        injectData("message", content: ["status": "login"])
        presenter?.onLogin(data)
    }

    // Send a message to the content server.
    func injectData(_ type: String, content: [String: Any]) {
        let data = [
            "type": type,
            "content": content
            ] as [String: Any]
        let json = JSON(data).stringValue() ?? ""
        let script = "window.postMessage(\(json), '\(self.webView.url?.absoluteString ?? "")');"
        webView.evaluateJavaScript(script, completionHandler: nil)
    }

    fileprivate func onCanLinkAccount(_ data: JSON) {
        //    // We need to confirm a relink - see shouldAllowRelink for more
        //    let ok = shouldAllowRelink(accountData.email);
        let ok = true
        injectData("message", content: ["status": "can_link_account", "data": ["ok": ok]])
    }
}

/*
 LeakAvoider prevents leaks with WKUserContentController
 http://stackoverflow.com/questions/26383031/wkwebview-causes-my-view-controller-to-leak
 */

class LeakAvoider: NSObject, WKScriptMessageHandler {
    weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
        super.init()
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        self.delegate?.userContentController(userContentController, didReceive: message)
    }
}

extension FxAView: UIGestureRecognizerDelegate {
    fileprivate func setupNavBar() {
        let leftButton = UIButton(title: Constant.string.close, imageName: nil)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)

        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        if let presenter = self.presenter {
            leftButton.rx.tap
                .bind(to: presenter.onClose)
                .disposed(by: self.disposeBag)

            self.navigationController?.interactivePopGestureRecognizer?.delegate = self
            self.navigationController?.interactivePopGestureRecognizer?.rx.event
                .map { _ -> Void in
                    return ()
                }
                .bind(to: presenter.onClose)
                .disposed(by: self.disposeBag)
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit
import RxSwift

class FxAView : UIViewController, FxAViewProtocol, WKNavigationDelegate {
    internal var presenter: FxAPresenter!
    private var webView: WKWebView
    private var disposeBag = DisposeBag()

    init(webView: WKWebView? = WKWebView()) {
        self.webView = webView!
        super.init(nibName: nil, bundle:nil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.webView = WKWebView()
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.navigationDelegate = self
        self.view = self.webView
        
        if (self.presenter != nil) {
            self.presenter.onViewReady()
        }
    }

    func loadRequest(_ urlRequest:URLRequest) {
        self.webView.load(urlRequest)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        presenter.webViewRequest(decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }
}

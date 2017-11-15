/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit
import RxSwift

class FxAView : UIViewController, FxAViewProtocol, WKNavigationDelegate {
    var webView: WKWebView
    private var presenter: FxAPresenter
    private var disposeBag = DisposeBag()

    init(webView: WKWebView? = WKWebView(), presenter: FxAPresenter? = FxAPresenter()) {
        self.webView = webView!
        self.presenter = presenter!

        super.init(nibName: nil, bundle:nil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.webView = WKWebView()
        self.presenter = FxAPresenter()

        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.presenter.view = self
        self.webView.navigationDelegate = self

        self.view = self.webView

        self.presenter.authenticateAndRetrieveScopedKey()
            .subscribe(onSuccess: { info in print(info) },
                    onError: {error in print(error)})
            .disposed(by: self.disposeBag)
    }

    func loadRequest(_ urlRequest:URLRequest) {
        self.webView.load(urlRequest)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        presenter.webViewRequest(decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }
}

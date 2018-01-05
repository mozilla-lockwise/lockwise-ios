/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit
import RxSwift
import RxCocoa

class FxAView : UIViewController, FxAViewProtocol, WKNavigationDelegate {
    internal var presenter: FxAPresenter!
    private var webView: WKWebView
    private var disposeBag = DisposeBag()

    override var preferredStatusBarStyle: UIStatusBarStyle { return UIStatusBarStyle.lightContent }
    
    init(webView: WKWebView = WKWebView()) {
        self.webView = webView
        super.init(nibName: nil, bundle: nil)
        self.presenter = FxAPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.webView.navigationDelegate = self
        self.view = self.webView
        styleNavigationBar()

        self.presenter.onViewReady()
    }

    func loadRequest(_ urlRequest:URLRequest) {
        self.webView.load(urlRequest)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        presenter.webViewRequest(decidePolicyFor: navigationAction, decisionHandler: decisionHandler)
    }

    private func styleNavigationBar() {
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: nil, action: nil)
        
        self.navigationItem.leftBarButtonItem!.rx.tap
                .bind(to: self.presenter.onCancel)
                .disposed(by: self.disposeBag)

        self.navigationItem.leftBarButtonItem!.setTitleTextAttributes([
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ], for: .normal)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
}

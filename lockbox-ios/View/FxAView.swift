/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit
import RxSwift
import RxCocoa
import SwiftyJSON
import FxAClient

class FxAView: UIViewController {
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
        self.webView.navigationDelegate = self
        self.view = self.webView
        self.setupNavBar()

        self.presenter?.onViewReady()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
}

extension FxAView: FxAViewProtocol {
    func loadRequest(_ urlRequest: URLRequest) {
        self.webView.load(urlRequest)
    }
}

extension FxAView: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let navigationURL = navigationAction.request.url,
           let expectedRedirectURL = URL(string: Constant.fxa.redirectURI) {
            if navigationURL.scheme == expectedRedirectURL.scheme &&
                       navigationURL.host == expectedRedirectURL.host &&
                       navigationURL.path == expectedRedirectURL.path {
               self.presenter?.matchingRedirectURLReceived(navigationURL)
                decisionHandler(.cancel)
                return
            }
        }

        decisionHandler(.allow)
    }
}

extension FxAView: UIGestureRecognizerDelegate {
    fileprivate func setupNavBar() {
        let leftButton = UIButton(title: Constant.string.close, imageName: nil)
        leftButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
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

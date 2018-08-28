/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit
import RxCocoa
import RxSwift

class StaticURLWebView: UIViewController {
    private var urlString: String
    private var navTitle: String
    private var presenter: StaticURLPresenter?

    var returnRoute: RouteAction
    private var activityIndicator: UIActivityIndicatorView?

    init(urlString: String, title: String, returnRoute: RouteAction) {
        self.urlString = urlString
        self.navTitle = title
        self.returnRoute = returnRoute

        super.init(nibName: nil, bundle: nil)
        self.presenter = StaticURLPresenter(view: self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let webView = WKWebView(frame: self.view.frame)
        self.styleNavigationBar()

        self.view.addSubview(webView)
        webView.navigationDelegate = self

        if let url = URL(string: self.urlString) {
            webView.load(URLRequest(url: url))
        }

        let indicator = UIActivityIndicatorView()
        indicator.center = self.view.center
        indicator.hidesWhenStopped = true
        indicator.activityIndicatorViewStyle = .gray
        indicator.transform = CGAffineTransform(scaleX: 3, y: 3) // Increase the size of the indicator
        indicator.startAnimating()
        self.view.addSubview(indicator)
        self.activityIndicator = indicator

        self.presenter?.onViewReady()
    }

    private func styleNavigationBar() {
        self.navigationItem.title = self.navTitle
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.navigationTitleFont
        ]

        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: Constant.string.close,
                style: .plain,
                target: nil,
                action: nil)
        self.navigationItem.leftBarButtonItem?.setTitleTextAttributes([
            .font: UIFont.navigationButtonFont
        ], for: .normal)
    }
}

extension StaticURLWebView: WKNavigationDelegate {
    func webView(_ webView: WKWebView,
                 didFinish navigation: WKNavigation!) {
        self.activityIndicator?.stopAnimating()
    }
}

extension StaticURLWebView: StaticURLViewProtocol {
    var closeTapped: Observable<Void>? {
        return self.navigationItem.leftBarButtonItem?.rx.tap.asObservable()
    }
}

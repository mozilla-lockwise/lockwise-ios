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
    private var webView = WKWebView()

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
        self.styleNavigationBar()

        self.view = webView

        if let url = URL(string: self.urlString) {
            webView.load(URLRequest(url: url))
        }

        self.presenter?.onViewReady()
    }

    private func styleNavigationBar() {
        self.navigationItem.title = self.navTitle
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: Constant.string.close,
                style: .plain,
                target: nil,
                action: nil)
    }
}

extension StaticURLWebView: StaticURLViewProtocol {
    var closeTapped: Observable<Void>? {
        return self.navigationItem.leftBarButtonItem?.rx.tap.asObservable()
    }
}

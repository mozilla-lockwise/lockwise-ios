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
    internal var presenter: StaticURLPresenter?

    var returnRoute: RouteAction
    private var webView = WKWebView()
    private var networkView: NoNetworkView

    init(urlString: String, title: String, returnRoute: RouteAction) {
        self.urlString = urlString
        self.navTitle = title
        self.returnRoute = returnRoute
        self.networkView = NoNetworkView.instanceFromNib()

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
        self.setupNetworkMessage()

        self.presenter?.onViewReady()
    }

    private func styleNavigationBar() {
        self.navigationItem.title = self.navTitle
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.navigationTitleFont
        ]

        self.navigationItem.largeTitleDisplayMode = .never

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(
                title: Constant.string.close,
                style: .plain,
                target: nil,
                action: nil)
        self.navigationItem.leftBarButtonItem?.setTitleTextAttributes([
            .font: UIFont.navigationButtonFont
        ], for: .normal)
    }

    fileprivate func setupNetworkMessage() {
        self.networkView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.networkView)
        self.networkView.addConstraint(NSLayoutConstraint(
            item: self.networkView,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .height,
            multiplier: 1,
            constant: 38)
        )

        self.view.addConstraints([
            NSLayoutConstraint(
                item: self.networkView,
                attribute: .leading,
                relatedBy: .equal,
                toItem: self.view.safeAreaLayoutGuide,
                attribute: .leading,
                multiplier: 1,
                constant: 0),
            NSLayoutConstraint(
                item: self.networkView,
                attribute: .trailing,
                relatedBy: .equal,
                toItem: self.view.safeAreaLayoutGuide,
                attribute: .trailing,
                multiplier: 1,
                constant: 0),
            NSLayoutConstraint(
                item: self.networkView,
                attribute: .top,
                relatedBy: .equal,
                toItem: self.view.safeAreaLayoutGuide,
                attribute: .top,
                multiplier: 1,
                constant: 0)
            ]
        )
    }
}

extension StaticURLWebView: StaticURLViewProtocol {
    func reload() {
        if let url = URL(string: self.urlString) {
            webView.load(URLRequest(url: url))
        }
    }

    var retryButtonTapped: Observable<Void> {
        return self.networkView.retryButton.rx.tap.asObservable()
    }

    var networkDisclaimerHidden: AnyObserver<Bool> {
        return self.networkView.rx.isHidden.asObserver()
    }

    var closeTapped: Observable<Void>? {
        return self.navigationItem.leftBarButtonItem?.rx.tap.asObservable()
    }
}

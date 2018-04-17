/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import WebKit
import UIKit

class SettingWebView: UIViewController {
    private var url: String
    private var navTitle: String
    private var webView = WKWebView()

    init(url: String, title: String) {
        self.url = url
        self.navTitle = title

        super.init(nibName: nil, bundle: nil)
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

        if let url = URL(string: self.url) {
            webView.load(URLRequest(url: url))
        }
    }

    private func styleNavigationBar() {
        self.navigationItem.title = self.navTitle
    }
}

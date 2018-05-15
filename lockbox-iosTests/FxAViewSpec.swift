/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import UIKit
import WebKit
import RxSwift

@testable import Lockbox

class FxAViewSpec: QuickSpec {
    class FakeFxAPresenter: FxAPresenter {
        var webViewRequestCalled = false
        var webViewNavigationAction: WKNavigationAction?
        var onViewReadyCalled = false

        override func onViewReady() {
            onViewReadyCalled = true
        }
    }

    class FakeWebView: WKWebView {
        var loadCalled = false
        var loadArgument: URLRequest?

        override func load(_ request: URLRequest) -> WKNavigation? {
            self.loadCalled = true
            self.loadArgument = request

            return nil
        }
    }

    var webView: FakeWebView!
    var presenter: FakeFxAPresenter!
    var subject: FxAView!

    override func spec() {
        beforeEach {
            self.webView = FakeWebView()

            self.subject = FxAView(webView: self.webView)
            self.presenter = FakeFxAPresenter(view: self.subject)
            self.subject.presenter = self.presenter

            self.subject.viewDidLoad()
        }

        it("informs the presenter when the view is ready") {
            expect(self.presenter.onViewReadyCalled).to(beTrue())
        }

        describe(".loadRequest()") {
            let request = URLRequest(url: URL(string: "www.mozilla.com")!)
            beforeEach {
                self.subject.loadRequest(request)
            }

            it("tells the webview to load the request") {
                expect(self.webView.loadCalled).to(beTrue())
                expect(self.webView.loadArgument).to(equal(request))
            }
        }
    }
}

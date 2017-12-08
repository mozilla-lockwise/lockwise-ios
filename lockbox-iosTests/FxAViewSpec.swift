/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import UIKit
import WebKit
import RxSwift

@testable import lockbox_ios

class FxAViewSpec : QuickSpec {
    class FakeFxAPresenter : FxAPresenter {
        var webViewRequestCalled = false
        var webViewNavigationAction:WKNavigationAction?
        var onViewReadyCalled = false

        override func webViewRequest(decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            self.webViewRequestCalled = true
            self.webViewNavigationAction = navigationAction
        }

        override func onViewReady() {
            onViewReadyCalled = true
        }
    }

    class FakeWebView : WKWebView {
        var loadCalled = false
        var loadArgument:URLRequest?

        override func load(_ request: URLRequest) -> WKNavigation? {
            self.loadCalled = true
            self.loadArgument = request

            return nil
        }
    }

    class FakeNavigationAction : WKNavigationAction {
        private var fakeRequest:URLRequest
        override var request:URLRequest {
            get {
                return self.fakeRequest
            }
        }

        init(request:URLRequest) {
            self.fakeRequest = request
        }
    }

    var webView:FakeWebView!
    var presenter:FakeFxAPresenter!
    var subject:FxAView!

    override func spec() {
        beforeEach {
            self.webView = FakeWebView()
            self.presenter = FakeFxAPresenter()

            self.subject = FxAView(webView: self.webView)
            self.subject.presenter = self.presenter

            self.subject.viewDidLoad()
        }

        it("informs the presenter when the view is ready") {

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

        describe(".webView(decidePolicy:decisionHandler:") {
            let request = URLRequest(url: URL(string: "www.mozilla.com")!)
            let action = FakeNavigationAction(request: request)
            let handler:((WKNavigationActionPolicy) -> Void) = { policy in }

            beforeEach {
                self.webView.navigationDelegate!.webView!(self.webView, decidePolicyFor: action, decisionHandler: handler)
            }

            it("passes the relevant information to the presenter to make a decision") {
                expect(self.presenter.webViewRequestCalled).to(beTrue())
                expect(self.presenter.webViewNavigationAction).to(equal(action))
            }
        }
    }
}


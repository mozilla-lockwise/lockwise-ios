/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import WebKit

@testable import Lockbox

class StaticURLWebViewSpec: QuickSpec {
    private let title = "a fake title"
    private let url = "http://www.mozilla.org/"
    private var subject: StaticURLWebView!

    override func spec() {
        describe("SettingWebView") {
            beforeEach {
                self.subject = StaticURLWebView(url: self.url, title: self.title)
                self.subject.viewDidLoad()
            }

            it("sets title") {
                expect(self.subject.navigationItem.title).to(equal(self.title))
            }

            it("loads url") {
                let webView = self.subject.view as! WKWebView
                expect(webView.url).to(equal(URL(string: self.url)))
            }

            it("sets status bar style") {
                expect(self.subject.preferredStatusBarStyle).to(equal(UIStatusBarStyle.lightContent))
            }
        }
    }
}

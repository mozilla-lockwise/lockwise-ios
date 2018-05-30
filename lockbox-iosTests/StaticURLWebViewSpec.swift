/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import WebKit
import RxTest
import RxSwift

@testable import Lockbox

class StaticURLWebViewSpec: QuickSpec {
    private let title = "a fake title"
    private let url = "http://www.mozilla.org/"
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
    private var subject: StaticURLWebView!

    override func spec() {
        describe("SettingWebView") {
            let returnRoute = MainRouteAction.list

            beforeEach {
                self.subject = StaticURLWebView(urlString: self.url, title: self.title, returnRoute: returnRoute)
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

            it("returns the passed route action") {
                let route = self.subject.returnRoute as! MainRouteAction
                expect(route).to(equal(returnRoute))
            }

            it("binds the left bar button item to the closeTapped observable") {
                let voidObserver = self.scheduler.createObserver(Void.self)

                self.subject.closeTapped?.bind(to: voidObserver).disposed(by: self.disposeBag)
                let barButton = self.subject.navigationItem.leftBarButtonItem!
                UIApplication.shared.sendAction(barButton.action!, to: barButton.target!, from: self, for: nil)

                expect(voidObserver.events.count).to(equal(1))
            }
        }
    }
}

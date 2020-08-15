/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class SplitViewSpec: QuickSpec {
    private var subject: SplitView!
    private var svDelegateImpl: SVDelegateImpl!

    class SVDelegateImpl: UISplitViewControllerDelegate {

    }

    override func spec() {
        describe("SplitView") {
            beforeEach {
                self.svDelegateImpl = SVDelegateImpl()
                self.subject = SplitView(delegate: self.svDelegateImpl)
            }

            it("sets preferredDisplayMode") {
                expect(self.subject.preferredDisplayMode).to(equal(UISplitViewController.DisplayMode.allVisible))
            }

            it("sets up two view controllers") {
                expect(self.subject.viewControllers.count).to(equal(2))
            }

            it("sets up two main navigation controllers") {
                expect(self.subject.viewControllers[0]).to(beAKindOf(MainNavigationController.self))
                expect(self.subject.viewControllers[1]).to(beAKindOf(MainNavigationController.self))
            }

            describe("detailView") {
                let vc = UINavigationController()
                beforeEach {
                    self.subject.detailView = vc
                }

                it("sets the second view controller") {
                    expect(self.subject.viewControllers[1]).to(be(vc))
                }

                it("returns the second view controller") {
                    expect(self.subject.detailView).to(be(vc))
                }
            }
        }
    }
}

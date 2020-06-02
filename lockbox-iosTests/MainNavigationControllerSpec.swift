/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

class MainNavigationControllerSpec: QuickSpec {
    var mainNavigationController: MainNavigationController!

    override func spec() {
        describe("MainNavigationController") {
            beforeEach {
                self.mainNavigationController = MainNavigationController(storyboardName: "ItemList", identifier: "itemlist")
            }

            it("sets item list as root") {
                expect(self.mainNavigationController.topViewController).to(beAnInstanceOf(ItemListView.self))
            }
        }

        describe("UINavigationController") {
            class LightNavBarController: UIViewController {
                override var preferredStatusBarStyle: UIStatusBarStyle {
                    return UIStatusBarStyle.lightContent
                }
            }

            it("defaults to default navbar theme") {
                let navController = UINavigationController()
                expect(navController.preferredStatusBarStyle).to(equal(UIStatusBarStyle.default))
            }

            it("respects root view controller navbar theme") {
                let navController = UINavigationController(rootViewController: LightNavBarController())
                expect(navController.preferredStatusBarStyle).to(equal(UIStatusBarStyle.default))
            }
        }
    }
}

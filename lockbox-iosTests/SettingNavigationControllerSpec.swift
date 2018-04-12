/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

class SettingNavigationControllerSpec: QuickSpec {
    var settingNavigationController: SettingNavigationController!

    override func spec() {
        describe("SettingNavigationController") {
            beforeEach {
                self.settingNavigationController = SettingNavigationController()
            }

            it("sets setting list as root") {
                expect(self.settingNavigationController.topViewController).to(beAnInstanceOf(SettingListView.self))
            }
        }
    }
}

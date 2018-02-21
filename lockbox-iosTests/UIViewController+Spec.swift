/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Quick
import Nimble

@testable import Lockbox

class ViewControllerSpec: QuickSpec {

    var subject: (UIViewController & ErrorView)!

    override func spec() {
        beforeEach {
            self.subject = UIViewController(nibName: nil, bundle: nil)
            UIApplication.shared.delegate!.window!!.rootViewController = self.subject

            self.subject.preloadView()
        }

        describe(".displayError()") {
            let error = NSError(domain: "someerror", code: -1)
            beforeEach {
                self.subject.displayError(error)
            }

            it("presents an alertcontroller with the appropriate messaging") {
                expect(self.subject.presentedViewController).toEventually(beAnInstanceOf(UIAlertController.self))

                let alertController = self.subject.presentedViewController as! UIAlertController

                expect(alertController.title).to(equal(error.localizedDescription))
                expect(alertController.actions[0].title).to(equal("OK"))
                expect(alertController.actions[0].style).to(equal(UIAlertActionStyle.cancel))
            }
        }
    }
}

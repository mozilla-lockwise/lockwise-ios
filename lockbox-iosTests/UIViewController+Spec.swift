/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class ViewControllerSpec: QuickSpec {

    var subject: (UIViewController & ErrorView & StatusAlertView & OptionSheetView)!

    override func spec() {
        beforeEach {
            self.subject = UIViewController(nibName: nil, bundle: nil)
            UIApplication.shared.delegate!.window!!.rootViewController = self.subject

            self.subject.preloadView()
        }

        xdescribe(".displayError()") {
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

        xdescribe(".displayTemporaryAlert") {
            let message = "Something copied to clipboard"

            beforeEach {
                self.subject.displayTemporaryAlert(message, timeout: 5)
            }

            it("displays a UIView temporarily") {
                expect(self.subject.view.subviews.first).toEventually(beAnInstanceOf(StatusAlert.self))

                let alert = self.subject.view.subviews.first as! StatusAlert

                expect(alert.messageLabel.text).to(equal(message))

                expect(self.subject.view.subviews.first).toEventually(beNil(), timeout: 6)
            }
        }

        xdescribe(".displayOptionSheet") {
            let title = "title!"
            let buttons = [
                OptionSheetButtonConfiguration(title: "something", tapObserver: nil, cancel: false),
                OptionSheetButtonConfiguration(title: "blah", tapObserver: nil, cancel: true)
            ]

            beforeEach {
                self.subject.displayOptionSheet(buttons: buttons, title: title)
            }

            it("displays an optionsheet alert controller") {
                expect(self.subject.presentedViewController).toEventually(beAnInstanceOf(UIAlertController.self))

                let alertController = self.subject.presentedViewController as! UIAlertController

                expect(alertController.preferredStyle).to(equal(UIAlertControllerStyle.actionSheet))

                expect(alertController.actions.first!.title).to(equal(buttons[0].title))
                expect(alertController.actions.first!.style).to(equal(UIAlertActionStyle.default))

                expect(alertController.actions[1].title).to(equal(buttons[1].title))
                expect(alertController.actions[1].style).to(equal(UIAlertActionStyle.cancel))
            }

            // testing note: UIAlertAction handlers _not_ tested here because it's heinous to do so in Swift.
        }
    }
}

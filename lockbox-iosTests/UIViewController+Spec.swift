/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Quick
import Nimble
import RxSwift
import RxCocoa
import RxTest

@testable import Lockbox

// NOTE: several of the specs in this suite are commented or pended because it is not possible to test
// animation code in BuddyBuild without them crashing.
class ViewControllerSpec: QuickSpec {
    private let disposeBag = DisposeBag()
    var subject: (UIViewController & StatusAlertView & AlertControllerView)!

    override func spec() {
        beforeEach {
            self.subject = UIViewController(nibName: nil, bundle: nil)
            UIApplication.shared.delegate!.window!!.rootViewController = self.subject

            self.subject.preloadView()
        }

        describe(".displayTemporaryAlert") {
            let message = "Something copied to clipboard"

            beforeEach {
                self.subject.displayTemporaryAlert(message, timeout: 5)
            }

            it("displays a UIView temporarily") {
                expect(self.subject.view.subviews.first).to(beAnInstanceOf(StatusAlert.self))

                let alert = self.subject.view.subviews.first as! StatusAlert

                expect(alert.messageLabel.text).to(equal(message))

//                expect(self.subject.view.subviews.first).toEventually(beNil(), timeout: 6)
            }
        }

        xdescribe(".displayOptionSheet") {
            let title = "title!"
            let buttons = [
                AlertActionButtonConfiguration(title: "something", tapObserver: nil, style: .default),
                AlertActionButtonConfiguration(title: "blah", tapObserver: nil, style: .cancel)
            ]

            beforeEach {
                self.subject.displayAlertController(buttons: buttons,
                                                    title: title,
                                                    message: nil,
                                                    style: .actionSheet)
            }

            it("displays an optionsheet alert controller") {
                expect(self.subject.presentedViewController).toEventually(beAnInstanceOf(UIAlertController.self))

                let alertController = self.subject.presentedViewController as! UIAlertController

                expect(alertController.preferredStyle).to(equal(UIAlertController.Style.actionSheet))

                expect(alertController.actions.first!.title).to(equal(buttons[0].title))
                expect(alertController.actions.first!.style).to(equal(UIAlertAction.Style.default))

                expect(alertController.actions[1].title).to(equal(buttons[1].title))
                expect(alertController.actions[1].style).to(equal(UIAlertAction.Style.cancel))
            }

            // testing note: UIAlertAction handlers _not_ tested here because it's heinous to do so in Swift.
        }

        describe("displaySpinner") {
            let dismissStub = PublishSubject<Void>()

            beforeEach {
                self.subject.displaySpinner(dismissStub.asDriver(onErrorJustReturn: ()), bag: self.disposeBag, message: "", completionMessage: "")
            }

            it("displays a spinner alert") {
                expect(self.subject.view.subviews.first).to(beAnInstanceOf(SpinnerAlert.self))
            }

            xit("dismisses the spinner on new dismiss events after a given delay") {
                dismissStub.onNext(())
                expect(self.subject.view.subviews.first).toEventually(beNil(), timeout: Constant.number.minimumSpinnerHUDTime + 1.0)
            }
        }
    }
}

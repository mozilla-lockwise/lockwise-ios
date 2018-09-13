/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class OnboardingConfirmationViewSpec: QuickSpec {
    class FakeOnboardingConfPresenter: OnboardingConfirmationPresenter {
        var onViewReadyCalled = false
        var onEncryptionLinkCalled = false

        override func onViewReady() {
            self.onViewReadyCalled = true
        }

        override func onEncryptionLinkTapped() {
            self.onEncryptionLinkCalled = true
        }
    }

    private var presenter: FakeOnboardingConfPresenter!
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
    var subject: OnboardingConfirmationView!

    override func spec() {
        describe("OnboardingConfirmationView") {
            beforeEach {
                let sb = UIStoryboard(name: "OnboardingConfirmation", bundle: nil)
                self.subject = sb.instantiateViewController(withIdentifier: "onboardingconfirmation") as? OnboardingConfirmationView
                self.presenter = FakeOnboardingConfPresenter(view: self.subject)
                self.subject.presenter = self.presenter

                self.subject.preloadView()
            }

            it("tells the presenter when the view is loaded") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            describe("finishButtonTapped") {
                var voidObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    voidObserver = self.scheduler.createObserver(Void.self)
                    self.subject.finishButtonTapped
                            .subscribe(voidObserver)
                            .disposed(by: self.disposeBag)

                    self.subject.finishButton.sendActions(for: .touchUpInside)
                }

                it("tells observers when button tapped") {
                    expect(voidObserver.events.count).to(equal(1))
                }
            }

            describe("textViewURL") {
                beforeEach {
                    _ = self.subject.textView(
                            self.subject.encryptionTextView,
                            shouldInteractWith: URL(string: Constant.app.securityFAQ)!,
                            in: NSMakeRange(33, 18)) // swiftlint:disable:this legacy_constructor
                }

                it("tells the presenter") {
                    expect(self.presenter.onEncryptionLinkCalled).to(beTrue())
                }
            }
        }
    }
}

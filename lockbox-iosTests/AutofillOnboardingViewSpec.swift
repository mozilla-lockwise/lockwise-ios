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

class AutofillOnboardingViewSpec: QuickSpec {
    class FakeAutofillOnboardingPresenter: AutofillOnboardingPresenter {
        var onViewReadyCalled = false

        override func onViewReady() {
            self.onViewReadyCalled = true
        }
    }

    private var presenter: FakeAutofillOnboardingPresenter!
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
    var subject: AutofillOnboardingView!

    override func spec() {
        describe("AutofillOnboardingView") {
            beforeEach {
                let sb = UIStoryboard(name: "AutofillOnboarding", bundle: nil)
                self.subject = sb.instantiateViewController(withIdentifier: "autofillonboarding") as? AutofillOnboardingView
                self.presenter = FakeAutofillOnboardingPresenter(view: self.subject)
                self.subject.presenter = self.presenter

                self.subject.preloadView()
            }

            it("tells the presenter when the view is loaded") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            describe("skipButtonTapped") {
                var voidObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    voidObserver = self.scheduler.createObserver(Void.self)
                    self.subject.skipButtonTapped
                        .subscribe(voidObserver)
                        .disposed(by: self.disposeBag)

                    self.subject.skipButton.sendActions(for: .touchUpInside)
                }

                it("tells observers when button tapped") {
                    expect(voidObserver.events.count).to(equal(1))
                }
            }

            describe("setupAutofillTapped") {
                var voidObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    voidObserver = self.scheduler.createObserver(Void.self)
                    self.subject.setupAutofillTapped
                        .subscribe(voidObserver)
                        .disposed(by: self.disposeBag)

                    self.subject.setupAutofillButton.sendActions(for: .touchUpInside)
                }

                it("tells observers when button tapped") {
                    expect(voidObserver.events.count).to(equal(1))
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import UIKit
import RxTest
import RxSwift
import RxCocoa

@testable import Lockbox

class WelcomeViewSpec: QuickSpec {
    class FakeLoginPresenter: WelcomePresenter {
        var onViewReadyCalled = false

        override func onViewReady() {
            onViewReadyCalled = true
        }
    }

    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
    private var presenter: FakeLoginPresenter!
    var subject: WelcomeView!

    override func spec() {
        describe("WelcomeView") {
            beforeEach {
                let sb = UIStoryboard(name: "Welcome", bundle: nil)
                self.subject = sb.instantiateViewController(withIdentifier: "welcome") as! WelcomeView
                self.presenter = FakeLoginPresenter(view: self.subject)
                self.subject.presenter = self.presenter

                _ = self.subject.view
            }

            it("informs the presenter when the view is ready") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            describe("fxasigninbutton") {
                var buttonObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    buttonObserver = self.scheduler.createObserver(Void.self)

                    self.subject.loginButtonPressed
                            .subscribe(buttonObserver)
                            .disposed(by: self.disposeBag)

                    self.subject.fxASigninButton.sendActions(for: .touchUpInside)
                }

                it("tells observers about button taps") {
                    expect(buttonObserver.events.count).to(be(1))
                }
            }
        }
    }
}

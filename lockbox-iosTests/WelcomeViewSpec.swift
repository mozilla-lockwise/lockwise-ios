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

                self.subject.preloadView()
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

            describe("biometricSignInButton") {
                var buttonObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    buttonObserver = self.scheduler.createObserver(Void.self)

                    self.subject.biometricSignInButtonPressed
                            .subscribe(buttonObserver)
                            .disposed(by: self.disposeBag)

                    self.subject.biometricSignInButton.sendActions(for: .touchUpInside)
                }

                it("tells observers about button taps") {
                    expect(buttonObserver.events.count).to(be(1))
                }
            }

            describe("firstTimeLoginMessageHidden") {
                beforeEach {
                    self.subject.firstTimeLoginMessageHidden.onNext(true)
                }

                it("updates the hidden value of the AccessLockboxMessage accordingly") {
                    expect(self.subject.accessLockboxMessage.isHidden).to(beTrue())
                }
            }

            describe("biometricAuthenticationPromptHidden") {
                beforeEach {
                    self.subject.biometricAuthenticationPromptHidden.onNext(true)
                }

                it("updates the hidden value of the biometric auth button accordingly") {
                    expect(self.subject.biometricSignInButton.isHidden).to(beTrue())
                }
            }

            describe("biometricSignInText") {
                let text = "sign in with your cat"

                beforeEach {
                    self.subject.biometricSignInText.onNext(text)
                }

                it("updates the text of the biometric auth button") {
                    expect(self.subject.biometricSignInButton.currentTitle).to(equal(text))
                }
            }

            describe("biometricImageName") {
                beforeEach {
                    self.subject.biometricImageName.onNext("confirm")
                }

                it("updates the image of the biometric auth button") {
                    let image = UIImage(named: "confirm")

                    expect(self.subject.biometricSignInButton.currentImage).to(equal(image))
                }
            }

            describe("fxaButtonTopSpacing") {
                let spacing: CGFloat = 44.0

                beforeEach {
                    self.subject.fxAButtonTopSpace.onNext(spacing)
                }

                it("updates the spacing of the top constraint on the FxA button") {
                    expect(self.subject.fxAButtonTopSpacing.constant).to(equal(spacing))
                }
            }
        }
    }
}

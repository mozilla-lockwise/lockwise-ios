/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Quick
import Nimble
import RxTest
import RxSwift

@testable import Lockbox

class BiometryOnboardingViewSpec: QuickSpec {
    class FakeBiometryOnboardingPresenter: BiometryOnboardingPresenter {
        var onViewReadyCalled = false

        override func onViewReady() {
            self.onViewReadyCalled = true
        }
    }

    private var presenter: FakeBiometryOnboardingPresenter!
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
    var subject: BiometryOnboardingView!

    override func spec() {
        describe("BiometryOnboardingView") {
            beforeEach {
                self.subject = UIStoryboard(name: "BiometryOnboarding", bundle: nil).instantiateViewController(withIdentifier: "biometryonboarding") as! BiometryOnboardingView
                self.presenter = FakeBiometryOnboardingPresenter(view: self.subject)
                self.subject.presenter = self.presenter

                self.subject.preloadView()
            }

            it("calls onViewReady") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            describe("enableTapped") {
                var enableObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    enableObserver = self.scheduler.createObserver(Void.self)

                    self.subject.enableTapped
                            .subscribe(enableObserver)
                            .disposed(by: self.disposeBag)

                    self.subject.enableButton.sendActions(for: .touchUpInside)
                }

                it("pushes taps to observers") {
                    expect(enableObserver.events.count).to(equal(1))
                }
            }

            describe("notNowTapped") {
                var notNowObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    notNowObserver = self.scheduler.createObserver(Void.self)

                    self.subject.notNowTapped
                            .subscribe(notNowObserver)
                            .disposed(by: self.disposeBag)

                    self.subject.notNowButton.sendActions(for: .touchUpInside)
                }

                it("pushes taps to observers") {
                    expect(notNowObserver.events.count).to(equal(1))
                }
            }

            describe("oniPhoneX") {
                it("returns the UIDevice value") {
                    if UIDevice.hasFaceID {
                        expect(self.subject.hasFaceID).to(beTrue())
                    } else {
                        expect(self.subject.hasFaceID).to(beFalse())
                    }
                }
            }

            describe("setBiometricImageName") {
                let imageName = "preferences"
                beforeEach {
                    self.subject.setBiometricsImageName(imageName)
                }

                it("sets the image") {
                    expect(self.subject.biometricImage.image).to(equal(UIImage(named: imageName)))
                }
            }

            describe("setBiometricImageName") {
                let title = "YOU GONNA TOUCH DIS"
                beforeEach {
                    self.subject.setBiometricsTitle(title)
                }

                it("sets the title") {
                    expect(self.subject.biometricTitle.text).to(equal(title))
                }
            }

            describe("setBiometricImageName") {
                let subtitle = "WE KNOW WHO YOU ARE"
                beforeEach {
                    self.subject.setBiometricsSubTitle(subtitle)
                }

                it("sets the title") {
                    expect(self.subject.biometricSubTitle.text).to(equal(subtitle))
                }
            }
        }
    }
}

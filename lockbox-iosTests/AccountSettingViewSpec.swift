/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Quick
import Nimble
import RxSwift
import RxTest
import RxCocoa

@testable import Lockbox

class AccountSettingViewSpec: QuickSpec {
    class FakeAccountSettingPresenter: AccountSettingPresenter {
        var unlinkAccountStub: TestableObserver<Void>!
        var settingTapStub: TestableObserver<Void>!

        override var unLinkAccountTapped: AnyObserver<Void> {
            return self.unlinkAccountStub.asObserver()
        }

        override var onSettingsTap: AnyObserver<Void> {
            return self.settingTapStub.asObserver()
        }

        var onViewReadyCalled = false

        override func onViewReady() {
            self.onViewReadyCalled = true
        }
    }

    private var presenter: FakeAccountSettingPresenter!
    var subject: AccountSettingView!

    private let disposeBag = DisposeBag()
    private let scheduler = TestScheduler(initialClock: 0)

    override func spec() {
        describe("AccountSettingView") {
            beforeEach {
                self.subject = UIStoryboard(name: "AccountSetting", bundle: nil)
                        .instantiateViewController(withIdentifier: "accountsetting") as? AccountSettingView

                self.presenter = FakeAccountSettingPresenter(view: self.subject)
                self.presenter.unlinkAccountStub = self.scheduler.createObserver(Void.self)
                self.presenter.settingTapStub = self.scheduler.createObserver(Void.self)

                self.subject.presenter = self.presenter

                self.subject.preloadView()
            }

            it("tells the presenter when the view is ready") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            describe("tapping the unlink account button") {
                beforeEach {
                    self.subject.unlinkAccountButton.sendActions(for: .touchUpInside)
                }

                it("tells the presenter") {
                    expect(self.presenter.unlinkAccountStub.events.count).to(equal(1))
                }
            }

            describe("tapping the back to settings button") {
                beforeEach {
                    (self.subject.navigationItem.leftBarButtonItem!.customView as! UIButton).sendActions(for: .touchUpInside)
                }

                it("tells the presenter") {
                    expect(self.presenter.settingTapStub.events.count).to(equal(1))
                }
            }

            describe("bind(displayName)") {
                let displayName = "squash"

                beforeEach {
                    self.subject.bind(displayName: Driver.just(displayName))
                }

                it("binds the displayName text to the username label") {
                    expect(self.subject.usernameLabel.text).to(equal(displayName))
                }
            }

            describe("bind(avatarImageData)") {
                let avatarImage = UIImage(named: "confirm")!
                let dataFromPlaceholder = UIImage(named: "avatar-placeholder")?.pngData()

                beforeEach {
                    let dataFromImage = avatarImage.pngData()!
                    self.subject.bind(avatarImage: Driver.just(dataFromImage))
                }

                it("changes the image to not have the placeholder") {
                    expect(self.subject.avatarImageView.image!.pngData()).notTo(equal(dataFromPlaceholder))
                }
            }
        }
    }
}

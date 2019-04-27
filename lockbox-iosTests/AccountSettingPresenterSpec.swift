/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest
import RxCocoa
import MozillaAppServices

@testable import Lockbox

class AccountSettingPresenterSpec: QuickSpec {
    class FakeAccountSettingView: AccountSettingViewProtocol {
        var avatarImageDataObserver: TestableObserver<Data>!
        var displayNameObserver: TestableObserver<String>!
        var displayAlertActionButtons: [AlertActionButtonConfiguration]?
        var displayAlertControllerTitle: String?
        var displayAlertControllerMessage: String?
        var fakeUnlinkAccountButtonPressed = PublishSubject<Void>()
        var fakeOnSettingsButtonPressed = PublishSubject<Void>()

        let disposeBag = DisposeBag()

        func bind(avatarImage: Driver<Data>) {
            avatarImage.drive(self.avatarImageDataObserver).disposed(by: self.disposeBag)
        }

        func bind(displayName: Driver<String>) {
            displayName.drive(self.displayNameObserver).disposed(by: self.disposeBag)
        }

        func displayAlertController(buttons: [AlertActionButtonConfiguration], title: String?, message: String?, style: UIAlertController.Style, barButtonItem: UIBarButtonItem?) {
            self.displayAlertActionButtons = buttons
            self.displayAlertControllerMessage = message
            self.displayAlertControllerTitle = title
        }

        var unLinkAccountButtonPressed: ControlEvent<Void> {
            return ControlEvent<Void>(events: fakeUnlinkAccountButtonPressed.asObservable())
        }

        var onSettingsButtonPressed: ControlEvent<Void>? {
            return ControlEvent<Void>(events: fakeOnSettingsButtonPressed.asObservable())
        }
    }

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    class FakeAccountStore: AccountStore {
        let profileStub = PublishSubject<Profile?>()

        override var profile: Observable<Profile?> {
            return self.profileStub.asObservable()
        }

        init(networkStore: AccountStoreSpec.FakeNetworkStore = AccountStoreSpec.FakeNetworkStore()) {
            super.init(networkStore: networkStore)
        }
    }

    private var view: FakeAccountSettingView!
    private var dispatcher: FakeDispatcher!
    private var accountStore: FakeAccountStore!
    var subject: AccountSettingPresenter!

    private let disposeBag = DisposeBag()
    private let scheduler = TestScheduler(initialClock: 0)

    override func spec() {
        describe("AccountSettingPresenter") {
            beforeEach {
                self.view = FakeAccountSettingView()
                self.view.avatarImageDataObserver = self.scheduler.createObserver(Data.self)
                self.view.displayNameObserver = self.scheduler.createObserver(String.self)

                self.dispatcher = FakeDispatcher()
                self.accountStore = FakeAccountStore()
                self.subject = AccountSettingPresenter(
                        view: self.view,
                        dispatcher: self.dispatcher,
                        accountStore: self.accountStore
                )
            }

            describe("onViewReady") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("displayName") {
                    // tricky to test because we can't construct FxAClient.Profile
                }

                describe("avatarImage") {
                    // ditto
                }
            }

            describe("unlinkAccountTapped") {
                beforeEach {
                    self.subject.onViewReady()
                    self.view.fakeUnlinkAccountButtonPressed.onNext(())
                }
                it("displays the alert controller") {
                    expect(self.view.displayAlertActionButtons).notTo(beNil())
                    expect(self.view.displayAlertControllerTitle).to(equal(String(format: Constant.string.confirmDialogTitle, Constant.string.productName)))
                    expect(self.view.displayAlertControllerMessage).to(equal(String(format: Constant.string.confirmDialogMessage, Constant.string.productName))
                }

                describe("unlinkAccountObserver") {
                    beforeEach {
                        self.view.displayAlertActionButtons![1].tapObserver?.onNext(())
                    }

                    it("sends the clear & reset actions") {
                        let accountAction = self.dispatcher.dispatchedActions.popLast() as! AccountAction
                        expect(accountAction).to(equal(.clear))

                        let dataStoreAction = self.dispatcher.dispatchedActions.popLast() as! DataStoreAction
                        expect(dataStoreAction).to(equal(.reset))

                        let credprovideraction = self.dispatcher.dispatchedActions.popLast() as! CredentialProviderAction
                        expect(credprovideraction).to(equal(.clear))
                    }
                }
            }

            describe("onSettingsTap") {
                beforeEach {
                    self.subject.onViewReady()
                    self.view.fakeOnSettingsButtonPressed.onNext(())
                }

                it("sends the settings list action") {
                    let argument = self.dispatcher.dispatchedActions.popLast() as! SettingRouteAction
                    expect(argument).to(equal(.list))
                }
            }
        }
    }
}

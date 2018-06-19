/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest
import RxCocoa
import FxAClient

@testable import Lockbox

class AccountSettingPresenterSpec: QuickSpec {
    class FakeAccountSettingView: AccountSettingViewProtocol {
        var avatarImageDataObserver: TestableObserver<Data>!
        var displayNameObserver: TestableObserver<String>!
        var displayAlertActionButtons: [AlertActionButtonConfiguration]?
        var displayAlertControllerTitle: String?
        var displayAlertControllerMessage: String?

        let disposeBag = DisposeBag()

        func bind(avatarImage: Driver<Data>) {
            avatarImage.drive(self.avatarImageDataObserver).disposed(by: self.disposeBag)
        }

        func bind(displayName: Driver<String>) {
            displayName.drive(self.displayNameObserver).disposed(by: self.disposeBag)
        }

        func displayAlertController(buttons: [AlertActionButtonConfiguration], title: String?, message: String?, style: UIAlertControllerStyle) {
            self.displayAlertActionButtons = buttons
            self.displayAlertControllerMessage = message
            self.displayAlertControllerTitle = title
        }
    }

    class FakeAccountStore: AccountStore {
        let profileStub = PublishSubject<Profile?>()

        override var profile: Observable<Profile?> {
            return self.profileStub.asObservable()
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeArgument = action
        }
    }

    class FakeAccountActionHandler: AccountActionHandler {
        var invokeArgument: AccountAction?

        override func invoke(_ action: AccountAction) {
            self.invokeArgument = action
        }
    }

    class FakeDataStoreActionHandler: DataStoreActionHandler {
        var invokeArgument: DataStoreAction?

        override func invoke(_ action: DataStoreAction) {
            self.invokeArgument = action
        }
    }

    private var view: FakeAccountSettingView!
    private var accountStore: FakeAccountStore!
    private var routeActionHandler: FakeRouteActionHandler!
    private var accountActionHandler: FakeAccountActionHandler!
    private var dataStoreActionHandler: FakeDataStoreActionHandler!
    var subject: AccountSettingPresenter!

    private let disposeBag = DisposeBag()
    private let scheduler = TestScheduler(initialClock: 0)

    override func spec() {
        describe("AccountSettingPresenter") {
            beforeEach {
                self.view = FakeAccountSettingView()
                self.view.avatarImageDataObserver = self.scheduler.createObserver(Data.self)
                self.view.displayNameObserver = self.scheduler.createObserver(String.self)

                self.accountStore = FakeAccountStore()
                self.routeActionHandler = FakeRouteActionHandler()
                self.accountStore = FakeAccountStore()
                self.accountActionHandler = FakeAccountActionHandler()
                self.dataStoreActionHandler = FakeDataStoreActionHandler()
                self.subject = AccountSettingPresenter(
                        view: self.view,
                        accountStore: self.accountStore,
                        routeActionHandler: self.routeActionHandler,
                        dataStoreActionHandler: self.dataStoreActionHandler,
                        accountActionHandler: self.accountActionHandler
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
                    let voidObservable = self.scheduler.createColdObservable([next(50, ())])

                    voidObservable
                            .bind(to: self.subject.unLinkAccountTapped)
                            .disposed(by: self.disposeBag)
                    self.scheduler.start()
                }
                it("displays the alert controller") {
                    expect(self.view.displayAlertActionButtons).notTo(beNil())
                    expect(self.view.displayAlertControllerTitle).to(equal(Constant.string.confirmDialogTitle))
                    expect(self.view.displayAlertControllerMessage).to(equal(Constant.string.confirmDialogMessage))
                }

                describe("unlinkAccountObserver") {
                    beforeEach {
                        self.view.displayAlertActionButtons![1].tapObserver?.onNext(())
                    }

                    it("sends the clear & reset actions") {
                        expect(self.dataStoreActionHandler.invokeArgument).to(equal(DataStoreAction.reset))
                        expect(self.accountActionHandler.invokeArgument).to(equal(AccountAction.clear))
                    }
                }
            }

            describe("onSettingsTap") {
                beforeEach {
                    let voidObservable = self.scheduler.createColdObservable([next(50, ())])

                    voidObservable
                            .bind(to: self.subject.onSettingsTap)
                            .disposed(by: self.disposeBag)

                    self.scheduler.start()
                }

                it("sends the settings list action") {
                    let argument = self.routeActionHandler.invokeArgument as! SettingRouteAction
                    expect(argument).to(equal(SettingRouteAction.list))
                }
            }
        }
    }
}

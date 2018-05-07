/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest
import RxCocoa

@testable import Firefox_Lockbox

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

    class FakeUserInfoStore: UserInfoStore {
        let profileStub = PublishSubject<ProfileInfo?>()

        override var profileInfo: Observable<ProfileInfo?> {
            return self.profileStub.asObservable()
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeArgument = action
        }
    }

    class FakeUserInfoActionHandler: UserInfoActionHandler {
        var invokeArgument: UserInfoAction?

        override func invoke(_ action: UserInfoAction) {
            self.invokeArgument = action
        }
    }

    private var view: FakeAccountSettingView!
    private var userInfoStore: FakeUserInfoStore!
    private var routeActionHandler: FakeRouteActionHandler!
    private var userInfoActionHandler: FakeUserInfoActionHandler!
    var subject: AccountSettingPresenter!

    private let disposeBag = DisposeBag()
    private let scheduler = TestScheduler(initialClock: 0)

    override func spec() {
        describe("AccountSettingPresenter") {
            beforeEach {
                self.view = FakeAccountSettingView()
                self.view.avatarImageDataObserver = self.scheduler.createObserver(Data.self)
                self.view.displayNameObserver = self.scheduler.createObserver(String.self)

                self.userInfoStore = FakeUserInfoStore()
                self.routeActionHandler = FakeRouteActionHandler()
                self.userInfoStore = FakeUserInfoStore()
                self.userInfoActionHandler = FakeUserInfoActionHandler()
                self.subject = AccountSettingPresenter(
                        view: self.view,
                        userInfoStore: self.userInfoStore,
                        routeActionHandler: self.routeActionHandler,
                        userInfoActionHandler: self.userInfoActionHandler
                )
            }

            describe("onViewReady") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("displayName") {
                    describe("when the profileInfo has a display name") {
                        let displayName = "meowskers"
                        beforeEach {
                            self.userInfoStore.profileStub.onNext(
                                    ProfileInfo.Builder()
                                            .displayName(displayName)
                                            .email("blah@blah.com")
                                            .build()
                            )
                        }

                        it("tells the view to display the display name") {
                            expect(self.view.displayNameObserver.events.last!.value.element).to(equal(displayName))
                        }
                    }

                    describe("when the profileInfo does not have a display name") {
                        let email = "meowskers@meow.com"
                        beforeEach {
                            self.userInfoStore.profileStub.onNext(
                                    ProfileInfo.Builder()
                                            .email(email)
                                            .build()
                            )
                        }

                        it("tells the view to display the email") {
                            expect(self.view.displayNameObserver.events.last!.value.element).to(equal(email))
                        }
                    }
                }

                describe("avatarImage") {
                    // tricky to test the network call here
                    xdescribe("when the profileInfo has an avatar url") {
                        let avatarURL = "https://i.pinimg.com/236x/f8/93/b2/f893b23eaffac078d529989aad2c714c.jpg"
                        beforeEach {
                            self.userInfoStore.profileStub.onNext(
                                    ProfileInfo.Builder()
                                            .avatar(avatarURL)
                                            .email("blah@blah.com")
                                            .build()
                            )
                        }

                        it("tells the view to display the avatar image data") {
                            expect(self.view.avatarImageDataObserver.events.last!.value.element).notTo(beNil())
                        }
                    }

                    describe("when the profileInfo does not have an avatar url") {
                        beforeEach {
                            self.userInfoStore.profileStub.onNext(ProfileInfo.Builder().build())
                        }

                        it("does not tell the view to display anything") {
                            expect(self.view.avatarImageDataObserver.events.last).to(beNil())
                        }
                    }
                }
            }

            describe("unlinkAccountTapped") {
                beforeEach {
                    let voidObservable = self.scheduler.createColdObservable([ next(50, ())])

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

                    it("sends the clear action") {
                        expect(self.userInfoActionHandler.invokeArgument).to(equal(UserInfoAction.clear))
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

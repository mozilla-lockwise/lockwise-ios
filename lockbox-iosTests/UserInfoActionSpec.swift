/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxCocoa
import Account
import FxAUtils

@testable import Lockbox

class UserInfoActionSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        var actionTypeArgument: Action?

        override func dispatch(action: Action) {
            self.actionTypeArgument = action
        }
    }

    private var dispatcher: FakeDispatcher!
    var subject: UserInfoActionHandler!

    override func spec() {
        describe("UserInfoActionHandler") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = UserInfoActionHandler(
                        dispatcher: self.dispatcher
                )
            }

            describe("invoke") {
                beforeEach {
                    self.subject.invoke(UserInfoAction.clear)
                }

                it("dispatches actions to the dispatcher") {
                    expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                    let argument = self.dispatcher.actionTypeArgument as! UserInfoAction
                    expect(argument).to(equal(UserInfoAction.clear))
                }
            }

            describe("notification center") {
                describe("nil FirefoxAccount FxAProfiles") {
                    beforeEach {
                        let notification = Notification(name: NotificationNames.FirefoxAccountProfileChanged, object: nil, userInfo: nil)
                        NotificationCenter.default.post(notification)
                    }

                    it("does nothing") {
                        expect(self.dispatcher.actionTypeArgument).to(beNil())
                    }
                }

                describe("firefox account changes with profile infos attached") {
                    let email = "butts@butts.com"
                    let displayName = "meow"

                    beforeEach {
                        let fxaAccount = FirefoxAccount(
                                configuration: LatestDevFirefoxAccountConfiguration(),
                                email: email,
                                uid: "fsdfdsfds",
                                deviceRegistration: nil,
                                declinedEngines: nil,
                                stateKeyLabel: "meow",
                                state: SeparatedState(),
                                deviceName: "buttphone")

                        let fxaProfile = Account.FirefoxAccount.FxAProfile(
                                email: "butts@butts.com",
                                displayName: displayName,
                                avatar: "www.pixturesyet.com"
                        )

                        fxaAccount.fxaProfile = fxaProfile

                        let notification = Notification(name: NotificationNames.FirefoxAccountProfileChanged, object: fxaAccount, userInfo: nil)
                        NotificationCenter.default.post(notification)
                    }

                    it("pushes the resulting profileinfo object to the observer") {
                        expect(self.dispatcher.actionTypeArgument).notTo(beNil())
                        let argument = self.dispatcher.actionTypeArgument as! UserInfoAction
                        let profileInfo = ProfileInfo.Builder().displayName(displayName).email(email).build()
                        expect(argument).to(equal(UserInfoAction.profileInfo(info: profileInfo)))
                    }
                }
            }
        }

        describe("UserInfoActrion") {
            describe("equality") {
                it("profileInfo actions are equal when the infos are equal") {
                    expect(UserInfoAction.profileInfo(info: ProfileInfo.Builder().build())).to(equal(UserInfoAction.profileInfo(info: ProfileInfo.Builder().build())))
                    expect(UserInfoAction.profileInfo(info: ProfileInfo.Builder().email("blah").build())).notTo(equal(UserInfoAction.profileInfo(info: ProfileInfo.Builder().build())))
                }

                it("load actions are always equal") {
                    expect(UserInfoAction.load).to(equal(UserInfoAction.load))
                }

                it("clear actions are always equal") {
                    expect(UserInfoAction.clear).to(equal(UserInfoAction.clear))
                }
            }
        }
    }
}

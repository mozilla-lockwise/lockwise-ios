/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift

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
                self.subject = UserInfoActionHandler(dispatcher: self.dispatcher)
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
        }

        describe("UserInfoAction") {
            describe("equality") {
                it("scopedKey actions are equal when the keys are equal") {
                    expect(UserInfoAction.scopedKey(key: "something")).to(equal(UserInfoAction.scopedKey(key: "something")))
                    expect(UserInfoAction.scopedKey(key: "something")).notTo(equal(UserInfoAction.scopedKey(key: "somethingElse")))
                }

                it("profileInfo actions are equal when the infos are equal") {
                    expect(UserInfoAction.profileInfo(info: ProfileInfo.Builder().uid("meh").build())).to(equal(UserInfoAction.profileInfo(info: ProfileInfo.Builder().uid("meh").build())))
                    expect(UserInfoAction.profileInfo(info: ProfileInfo.Builder().uid("blah").build())).notTo(equal(UserInfoAction.profileInfo(info: ProfileInfo.Builder().uid("meh").build())))
                }

                it("profileInfo actions are equal when the infos are equal") {
                    expect(UserInfoAction.oauthInfo(info: OAuthInfo.Builder().accessToken("meh").build())).to(equal(UserInfoAction.oauthInfo(info: OAuthInfo.Builder().accessToken("meh").build())))
                    expect(UserInfoAction.oauthInfo(info: OAuthInfo.Builder().accessToken("blah").build())).notTo(equal(UserInfoAction.oauthInfo(info: OAuthInfo.Builder().accessToken("meh").build())))
                }

                it("biometricLogin is equal when the enabled value is the same") {
                    expect(UserInfoAction.biometricLogin(enabled: true)).to(equal(UserInfoAction.biometricLogin(enabled: true)))
                    expect(UserInfoAction.biometricLogin(enabled: true)).notTo(equal(UserInfoAction.biometricLogin(enabled: false)))
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

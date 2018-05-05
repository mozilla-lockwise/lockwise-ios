/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift

@testable import Lockbox

class AutoLockStoreSpec: QuickSpec {

    class FakeDispatcher: Dispatcher {

    }

    class FakeSettingActionHandler: SettingActionHandler {
        var action: SettingAction?

        override func invoke(_ action: SettingAction) {
            self.action = action
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var action: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.action = action
        }
    }

    var dispatcher: FakeDispatcher!
    var userDefaults: UserDefaults!
    var settingActionHandler: FakeSettingActionHandler!
    var routeActionHandler: FakeRouteActionHandler!

    var subject: AutoLockStore!

    override func spec() {
        describe("AutoLockStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.settingActionHandler = FakeSettingActionHandler()
                self.routeActionHandler = FakeRouteActionHandler()
                self.userDefaults = UserDefaults.standard

                self.subject = AutoLockStore(dispatcher: self.dispatcher,
                                             userDefaults: UserDefaults.standard,
                                             settingActionHandler: self.settingActionHandler,
                                             routeActionHandler: self.routeActionHandler)
            }

            describe("backgrounding app") {
                describe("with auto lock setting on OnAppExit") {
                    beforeEach {
                        self.userDefaults.set(AutoLockSetting.OnAppExit.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                        self.dispatcher.dispatch(action: LifecycleAction.background)
                    }

                    it("locks app") {
                        expect(self.settingActionHandler.action).to(equal(SettingAction.visualLock(locked: true)))
                        expect(self.routeActionHandler.action as? LoginRouteAction).to(equal(LoginRouteAction.welcome))
                        expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }

                describe("with auto lock setting on never") {
                    beforeEach {
                        self.userDefaults.removeObject(forKey: SettingKey.autoLockTimerDate.rawValue)
                        self.userDefaults.set(AutoLockSetting.Never.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                        self.dispatcher.dispatch(action: LifecycleAction.background)
                    }

                    it("does not lock app") {
                        expect(self.settingActionHandler.action).to(beNil())
                        expect(self.routeActionHandler.action).to(beNil())
                        expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }
            }

            describe("onLock setting changed") {
                describe("to unlock") {
                    describe("auto lock timer is a time interval") {
                        beforeEach {
                            UserDefaults.standard.set(true, forKey: SettingKey.locked.rawValue)
                            self.userDefaults.set(AutoLockSetting.FiveMinutes.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                            UserDefaults.standard.set(false, forKey: SettingKey.locked.rawValue)
                        }

                        it("sets the timer") {
                            expect(self.subject.timer).toNot(beNil())
                        }

                        it("sets the timer value from user defaults") {
                            expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).toNot(beNil())
                        }
                    }

                    it("doesn't set timer for AutoLockSetting.Never") {
                        self.userDefaults.set(true, forKey: SettingKey.locked.rawValue)
                        self.userDefaults.set(AutoLockSetting.Never.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                        self.userDefaults.set(false, forKey: SettingKey.locked.rawValue)
                        expect(self.subject.timer?.isValid).to(beFalsy())
                        expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).to(beNil())
                    }

                    it("doesn't set timer for AutoLockSetting.OnAppExit") {
                        self.userDefaults.set(AutoLockSetting.OnAppExit.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                        self.userDefaults.set(false, forKey: SettingKey.locked.rawValue)
                        expect(self.subject.timer?.isValid).to(beFalsy())
                        expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }

                describe("to lock") {
                    beforeEach {
                        self.userDefaults.set(true, forKey: SettingKey.locked.rawValue)
                    }

                    it("stops the timer") {
                        expect(self.subject.timer?.isValid).to(beFalsy())
                        expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }
            }
        }
    }
}

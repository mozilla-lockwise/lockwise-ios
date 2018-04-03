/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

class SettingActionSpec: QuickSpec {
    class FakeUserDefaults: UserDefaults {
        var boolName: String?
        var setBool: Bool?
        var stringName: String?
        var setString: String?

        override func set(_ value: Bool, forKey defaultName: String) {
            self.boolName = defaultName
            self.setBool = value
        }

        override func set(_ value: Any?, forKey defaultName: String) {
            self.stringName = defaultName
            self.setString = value as? String
        }
    }

    class FakeDispatcher: Dispatcher {
        var actionTypeArguments: [Action] = []

        override func dispatch(action: Action) {
            self.actionTypeArguments.append(action)
        }
    }

    private var userDefaults: FakeUserDefaults!
    private var dispatcher: FakeDispatcher!
    var subject: SettingActionHandler!

    override func spec() {
        describe("SettingActionHandler") {
            beforeEach {
                self.userDefaults = FakeUserDefaults()
                self.dispatcher = FakeDispatcher()
                self.subject = SettingActionHandler(dispatcher: self.dispatcher, userDefaults: self.userDefaults)
            }

            describe(".invoke()") {
                describe(".biometricLoginEnabled") {
                    let enabled = true

                    beforeEach {
                        self.subject.invoke(.biometricLogin(enabled: enabled))
                    }

                    it("sets the appropriate value for key in userdefaults") {
                        expect(self.userDefaults.setBool).to(equal(enabled))
                        expect(self.userDefaults.boolName).to(equal(SettingKey.biometricLogin.rawValue))
                    }

                    it("tells the dispatcher") {
                        let argument = self.dispatcher.actionTypeArguments.popLast() as! SettingAction
                        expect(argument).to(equal(SettingAction.biometricLogin(enabled: enabled)))
                    }
                }

                describe(".autolock") {
                    let autoLockSetting = AutoLockSetting.TwelveHours

                    beforeEach {
                        self.subject.invoke(.autoLock(timeout: autoLockSetting))
                    }

                    it("sets the appropriate value for key in userdefaults") {
                        expect(self.userDefaults.setString).to(equal(autoLockSetting.rawValue))
                        expect(self.userDefaults.stringName).to(equal(SettingKey.autoLock.rawValue))
                    }

                    it("tells the dispatcher") {
                        let argument = self.dispatcher.actionTypeArguments.popLast() as! SettingAction
                        expect(argument).to(equal(SettingAction.autoLock(timeout: autoLockSetting)))
                    }
                }

                describe(".reset") {
                    beforeEach {
                        self.subject.invoke(.reset)
                    }

                    it("sets the appropriate value for key in userdefaults") {
                        expect(self.userDefaults.setString).to(equal(Constant.setting.defaultAutoLockTimeout.rawValue))
                        expect(self.userDefaults.stringName).to(equal(SettingKey.autoLock.rawValue))
                        expect(self.userDefaults.setBool).to(equal(Constant.setting.defaultBiometricLockEnabled))
                        expect(self.userDefaults.boolName).to(equal(SettingKey.biometricLogin.rawValue))
                    }

                    it("tells the dispatcher") {
                        let argument = self.dispatcher.actionTypeArguments.popLast() as! SettingAction
                        expect(argument).to(equal(SettingAction.reset))
                    }
                }
            }
        }

        describe("SettingAction") {
            describe("equality") {
                it("biometric login enabled is equal based on the enabled values") {
                    expect(SettingAction.biometricLogin(enabled: true)).to(equal(SettingAction.biometricLogin(enabled: true)))
                    expect(SettingAction.biometricLogin(enabled: true)).notTo(equal(SettingAction.biometricLogin(enabled: false)))
                }

                it("autoLock is equal based on the autolock values") {
                    expect(SettingAction.autoLock(timeout: AutoLockSetting.TwelveHours)).to(equal(SettingAction.autoLock(timeout: AutoLockSetting.TwelveHours)))
                    expect(SettingAction.autoLock(timeout: AutoLockSetting.TwentyFourHours)).notTo(equal(SettingAction.autoLock(timeout: AutoLockSetting.TwelveHours)))
                }

                it("reset is always equal") {
                    expect(SettingAction.reset).to(equal(SettingAction.reset))
                }

                it("different enum values are not equal") {
                    expect(SettingAction.autoLock(timeout: AutoLockSetting.TwentyFourHours)).notTo(equal(SettingAction.biometricLogin(enabled: true)))
                    expect(SettingAction.reset).notTo(equal(SettingAction.biometricLogin(enabled: true)))
                }
            }
        }
    }
}

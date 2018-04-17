/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

class SettingActionSpec: QuickSpec {
    class FakeUserDefaults: UserDefaults {
        var bools: [String: Bool] = [:]
        var strings: [String: String] = [:]

        override func set(_ value: Bool, forKey defaultName: String) {
            self.bools[defaultName] = value
        }

        override func set(_ value: Any?, forKey defaultName: String) {
            self.strings[defaultName] = value as? String
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
                        expect(self.userDefaults.bools[SettingKey.biometricLogin.rawValue]).to(equal(enabled))
                    }

                    it("tells the dispatcher") {
                        let argument = self.dispatcher.actionTypeArguments.popLast() as! SettingAction
                        expect(argument).to(equal(SettingAction.biometricLogin(enabled: enabled)))
                    }
                }

                describe(".autolock") {
                    let autoLockSetting = AutoLockSetting.TwelveHours

                    beforeEach {
                        self.subject.invoke(.autoLockTime(timeout: autoLockSetting))
                    }

                    it("sets the appropriate value for key in userdefaults") {
                        expect(self.userDefaults.strings[SettingKey.autoLockTime.rawValue]).to(equal(autoLockSetting.rawValue))
                    }

                    it("tells the dispatcher") {
                        let argument = self.dispatcher.actionTypeArguments.popLast() as! SettingAction
                        expect(argument).to(equal(SettingAction.autoLockTime(timeout: autoLockSetting)))
                    }
                }

                describe(".lock") {
                    let locked = true

                    beforeEach {
                        self.subject.invoke(.visualLock(locked: locked))
                    }

                    it("sets the appropriate value for key in userdefaults") {
                        expect(self.userDefaults.bools[SettingKey.locked.rawValue]).to(equal(locked))
                    }

                    it("tells the dispatcher") {
                        let argument = self.dispatcher.actionTypeArguments.popLast() as! SettingAction
                        expect(argument).to(equal(SettingAction.visualLock(locked: locked)))
                    }
                }

                describe(".preferredBrowser") {
                    let browserSetting = PreferredBrowserSetting.Firefox

                    beforeEach {
                        self.subject.invoke(.preferredBrowser(browser: .Firefox))
                    }

                    it("sets the appropriate value for key in userdefaults") {
                        expect(self.userDefaults.strings[SettingKey.preferredBrowser.rawValue]).to(equal(browserSetting.rawValue))
                    }

                    it("tells the dispatcher") {
                        let argument = self.dispatcher.actionTypeArguments.popLast() as! SettingAction
                        expect(argument).to(equal(SettingAction.preferredBrowser(browser: browserSetting)))
                    }
                }

                describe(".reset") {
                    beforeEach {
                        self.subject.invoke(.reset)
                    }

                    it("sets the appropriate value for key in userdefaults") {
                        expect(self.userDefaults.strings[SettingKey.autoLockTime.rawValue]).to(equal(Constant.setting.defaultAutoLockTimeout.rawValue))
                        expect(self.userDefaults.bools[SettingKey.biometricLogin.rawValue]).to(equal(Constant.setting.defaultBiometricLockEnabled))
                        expect(self.userDefaults.bools[SettingKey.locked.rawValue]).to(equal(Constant.setting.defaultLockedState))
                        expect(self.userDefaults.strings[SettingKey.preferredBrowser.rawValue]).to(equal(Constant.setting.defaultPreferredBrowser.rawValue))
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
                    expect(SettingAction.autoLockTime(timeout: AutoLockSetting.TwelveHours)).to(equal(SettingAction.autoLockTime(timeout: AutoLockSetting.TwelveHours)))
                    expect(SettingAction.autoLockTime(timeout: AutoLockSetting.TwentyFourHours)).notTo(equal(SettingAction.autoLockTime(timeout: AutoLockSetting.TwelveHours)))
                }

                it("lock is equal based on the locked value") {
                    expect(SettingAction.visualLock(locked: true)).to(equal(SettingAction.visualLock(locked: true)))
                    expect(SettingAction.visualLock(locked: true)).notTo(equal(SettingAction.visualLock(locked: false)))
                }

                it("reset is always equal") {
                    expect(SettingAction.reset).to(equal(SettingAction.reset))
                }

                it("different enum values are not equal") {
                    expect(SettingAction.autoLockTime(timeout: AutoLockSetting.TwentyFourHours)).notTo(equal(SettingAction.biometricLogin(enabled: true)))
                    expect(SettingAction.reset).notTo(equal(SettingAction.biometricLogin(enabled: true)))
                }
            }
        }
    }
}

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

                describe(".recordUsageData") {
                    beforeEach {
                        self.subject.invoke(.recordUsageData(enabled: false))
                    }

                    it("sets the appropriate value for the key in userdefaults") {
                        expect(self.userDefaults.bools[SettingKey.recordUsageData.rawValue]).to(beFalse())
                    }

                    it("tells the dispatcher") {
                        let argument = self.dispatcher.actionTypeArguments.popLast() as! SettingAction
                        expect(argument).to(equal(SettingAction.recordUsageData(enabled: false)))
                    }
                }

                describe(".reset") {
                    beforeEach {
                        self.subject.invoke(.reset)
                    }

                    it("sets the appropriate value for key in userdefaults") {
                        expect(self.userDefaults.strings[SettingKey.autoLockTime.rawValue]).to(equal(Constant.setting.defaultAutoLockTimeout.rawValue))
                        expect(self.userDefaults.strings[SettingKey.preferredBrowser.rawValue]).to(equal(Constant.setting.defaultPreferredBrowser.rawValue))
                        expect(self.userDefaults.bools[SettingKey.recordUsageData.rawValue]).to(equal(Constant.setting.defaultRecordUsageData))
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
                it("autoLock is equal based on the autolock values") {
                    expect(SettingAction.autoLockTime(timeout: AutoLockSetting.TwelveHours)).to(equal(SettingAction.autoLockTime(timeout: AutoLockSetting.TwelveHours)))
                    expect(SettingAction.autoLockTime(timeout: AutoLockSetting.TwentyFourHours)).notTo(equal(SettingAction.autoLockTime(timeout: AutoLockSetting.TwelveHours)))
                }

                it("reset is always equal") {
                    expect(SettingAction.reset).to(equal(SettingAction.reset))
                }

                it("different enum values are not equal") {
                    expect(SettingAction.autoLockTime(timeout: AutoLockSetting.TwentyFourHours)).notTo(equal(SettingAction.reset))
                }
            }

            describe("telemetry") {
                it("event method should equal settingChanged") {
                    expect(SettingAction.visualLock(locked: true).eventMethod).to(equal(TelemetryEventMethod.settingChanged))
                }

                it("event object should be the setting that changed") {
                    expect(SettingAction.biometricLogin(enabled: true).eventObject).to(equal(TelemetryEventObject.settingsBiometricLogin))
                    expect(SettingAction.autoLockTime(timeout: AutoLockSetting.TwentyFourHours).eventObject).to(equal(TelemetryEventObject.settingsAutolockTime))
                    expect(SettingAction.visualLock(locked: true).eventObject).to(equal(TelemetryEventObject.settingsVisualLock))
                    expect(SettingAction.preferredBrowser(browser: PreferredBrowserSetting.Firefox).eventObject).to(equal(TelemetryEventObject.settingsPreferredBrowser))
                    expect(SettingAction.reset.eventObject).to(equal(TelemetryEventObject.settingsReset))
                    expect(SettingAction.recordUsageData(enabled: true).eventObject).to(equal(TelemetryEventObject.settingsRecordUsageData))
                }

                it("telemetry event value is equal to setting value") {
                    expect(SettingAction.biometricLogin(enabled: true).value).to(equal("true"))
                    expect(SettingAction.recordUsageData(enabled: true).value).to(equal("true"))
                    expect(SettingAction.visualLock(locked: true).value).to(equal("true"))
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

class SettingActionSpec: QuickSpec {
    override func spec() {
        describe("SettingAction") {
            describe("equality") {
                it("autoLock is equal based on the autolock values") {
                    expect(SettingAction.autoLockTime(timeout: Setting.AutoLock.TwelveHours)).to(equal(SettingAction.autoLockTime(timeout: Setting.AutoLock.TwelveHours)))
                    expect(SettingAction.autoLockTime(timeout: Setting.AutoLock.TwentyFourHours)).notTo(equal(SettingAction.autoLockTime(timeout: Setting.AutoLock.TwelveHours)))
                }

                it("reset is always equal") {
                    expect(SettingAction.reset).to(equal(SettingAction.reset))
                }

                it("different enum values are not equal") {
                    expect(SettingAction.autoLockTime(timeout: Setting.AutoLock.TwentyFourHours)).notTo(equal(SettingAction.reset))
                }
            }

            describe("telemetry") {
                it("event method should equal settingChanged") {
                    expect(SettingAction.reset.eventMethod).to(equal(TelemetryEventMethod.settingChanged))
                }

                it("event object should be the setting that changed") {
                    expect(SettingAction.autoLockTime(timeout: Setting.AutoLock.TwentyFourHours).eventObject).to(equal(TelemetryEventObject.settingsAutolockTime))
                    expect(SettingAction.preferredBrowser(browser: Setting.PreferredBrowser.Firefox).eventObject).to(equal(TelemetryEventObject.settingsPreferredBrowser))
                    expect(SettingAction.reset.eventObject).to(equal(TelemetryEventObject.settingsReset))
                    expect(SettingAction.recordUsageData(enabled: true).eventObject).to(equal(TelemetryEventObject.settingsRecordUsageData))
                }

                it("telemetry event value is equal to setting value") {
                    expect(SettingAction.recordUsageData(enabled: true).value).to(equal("true"))
                }
            }
        }
    }
}

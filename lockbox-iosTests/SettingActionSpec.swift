/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble

@testable import Lockbox

class FakeApplication: OpenUrlProtocol {
    var openArgument: URL?
    var canOpenURLArgument: URL?

    func open(_ url: URL, options: [UIApplication.OpenExternalURLOptionsKey: Any], completionHandler completion: ((Bool) -> Void)?) {
        self.openArgument = url
    }
    func canOpenURL(_ url: URL) -> Bool {
        self.canOpenURLArgument = url
        return true
    }
}

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

        describe("Setting") {
            describe("PreferredBrowser") {
                describe("getPreferredBrowserDeeplink") {

                    let testUrl = "https://github.com/mozilla-lockbox/lockbox-ios"

                    it("creates safari deeplinks") {
                        expect(Setting.PreferredBrowser.Safari.getPreferredBrowserDeeplink(url: testUrl)?.absoluteString).to(equal(testUrl))
                    }

                    it("creates firefox deeplinks") {
                        expect(Setting.PreferredBrowser.Firefox.getPreferredBrowserDeeplink(url: testUrl)?.absoluteString).to(equal("firefox://open-url?url=https%3A%2F%2Fgithub.com%2Fmozilla-lockbox%2Flockbox-ios"))
                    }

                    it("creates focus deeplinks") {
                        expect(Setting.PreferredBrowser.Focus.getPreferredBrowserDeeplink(url: testUrl)?.absoluteString).to(equal("firefox-focus://open-url?url=https%3A%2F%2Fgithub.com%2Fmozilla-lockbox%2Flockbox-ios"))
                    }

                    it("creates chrome https deeplinks") {
                        expect(Setting.PreferredBrowser.Chrome.getPreferredBrowserDeeplink(url: testUrl)?.absoluteString).to(equal("googlechromes://github.com/mozilla-lockbox/lockbox-ios"))
                    }

                    it("creates chrome http deeplinks") {
                        expect(Setting.PreferredBrowser.Chrome.getPreferredBrowserDeeplink(url: "http://mozilla.org")?.absoluteString).to(equal("googlechrome://mozilla.org"))
                    }
                }

                describe("canOpenBrowser") {

                    var application: FakeApplication!

                    beforeEach {
                        application = FakeApplication()
                    }

                    it("tries to open browser") {
                        expect(Setting.PreferredBrowser.Safari.canOpenBrowser(application: application)).to(beTrue())
                        expect(application.canOpenURLArgument?.absoluteString).toNot(beNil())
                    }

                    it("uses an http link for chrome") {
                        expect(Setting.PreferredBrowser.Chrome.canOpenBrowser(application: application)).to(beTrue())
                        expect(application.canOpenURLArgument?.absoluteString).to(equal("googlechrome://mozilla.org"))
                    }
                }
            }
        }
    }
}

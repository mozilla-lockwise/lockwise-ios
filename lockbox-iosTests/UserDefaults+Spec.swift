/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest
import RxCocoa
import Glean

@testable import Lockbox

class UserDefaultSpec: QuickSpec {
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()

    override func spec() {
        describe("onAutoLockSetting") {
            var autoLockSettingObserver = self.scheduler.createObserver(Setting.AutoLock.self)

            beforeEach {
                autoLockSettingObserver = self.scheduler.createObserver(Setting.AutoLock.self)

                UserDefaults.standard.onAutoLockTime
                        .subscribe(autoLockSettingObserver)
                        .disposed(by: self.disposeBag)
            }

            it("pushes new values for the UserDefaultKey to observers") {
                UserDefaults.standard.set(Setting.AutoLock.OneHour.rawValue, forKey: UserDefaultKey.autoLockTime.rawValue)

                expect(autoLockSettingObserver.events.last!.value.element).to(equal(Setting.AutoLock.OneHour))
            }

            it("pushes the default value when a meaningless autolock time is set") {
                UserDefaults.standard.set("FOREVER", forKey: UserDefaultKey.autoLockTime.rawValue)

                expect(autoLockSettingObserver.events.last!.value.element).to(equal(Constant.setting.defaultAutoLock))
            }
        }

        describe("onPreferredBrowser") {
            var preferredBrowserSettingObserver: TestableObserver<Setting.PreferredBrowser>!

            beforeEach {
                preferredBrowserSettingObserver = self.scheduler.createObserver(Setting.PreferredBrowser.self)
                UserDefaults.standard.onPreferredBrowser
                        .subscribe(preferredBrowserSettingObserver)
                        .disposed(by: self.disposeBag)
            }

            it("pushes new values for theUserDefaultKey to observers") {
                UserDefaults.standard.set(Setting.PreferredBrowser.Firefox.rawValue, forKey: LocalUserDefaultKey.preferredBrowser.rawValue)
                if Setting.PreferredBrowser.Firefox.canOpenBrowser() {
                    expect(preferredBrowserSettingObserver.events.last!.value.element).to(equal(Setting.PreferredBrowser.Firefox))
                } else {
                    expect(preferredBrowserSettingObserver.events.last!.value.element).to(equal(Setting.PreferredBrowser.Safari))
                }
            }
        }

        describe("preferredBrowserNotOpen") {
            // Tests case where preferred browser cannot be opened
            // This case can occur if a user sets preferred browser to a third-party browser then deletes that app
            // If browser cannot be opened, preferred browser remains stored but defaults to Safari within the client
            let canOpenBrowser = false
            var preferredBrowserSettingObserver: TestableObserver<Setting.PreferredBrowser>!

            beforeEach {
                preferredBrowserSettingObserver = self.scheduler.createObserver(Setting.PreferredBrowser.self)
                UserDefaults.standard.onPreferredBrowser
                        .subscribe(preferredBrowserSettingObserver)
                        .disposed(by: self.disposeBag)
            }

            it("pushes new values for theUserDefaultKey to observers") {
                UserDefaults.standard.set(Setting.PreferredBrowser.Firefox.rawValue, forKey: LocalUserDefaultKey.preferredBrowser.rawValue)
                if canOpenBrowser {
                    expect(preferredBrowserSettingObserver.events.last!.value.element).to(equal(Setting.PreferredBrowser.Firefox))
                } else {
                    expect(preferredBrowserSettingObserver.events.last!.value.element).to(equal(Setting.PreferredBrowser.Safari))
                }
            }
        }

        describe("onRecordUsageData") {
            var recordUsageDataSettingObserver: TestableObserver<Bool>!

            beforeEach {
                recordUsageDataSettingObserver = self.scheduler.createObserver(Bool.self)
                UserDefaults.standard.onRecordUsageData
                        .subscribe(recordUsageDataSettingObserver)
                        .disposed(by: self.disposeBag)
            }

            it("pushs new values for the correct setting key") {
                UserDefaults.standard.set(false, forKey: LocalUserDefaultKey.recordUsageData.rawValue)
                expect(recordUsageDataSettingObserver.events.last!.value.element).to(beFalse())
            }

            it("triggers Glean.setUploadEnabled() before Glean.initialize()") {
                // Set the default value to false since Glean upload enabled flag defaults to true.
                UserDefaultStore.shared.userDefaults
                    .set(false, forKey: LocalUserDefaultKey.recordUsageData.rawValue)
                // Create the ActionHandler which will should call `Glean.shared.setUploadEnabled()`
                // and `Glean.shared.initialize()`.  Since upload defaults to true in Glean, if this
                // is false it means that initialize is called after setUploadEnabled has been called
                // with the value that was just set above.
                _ = GleanActionHandler()
                expect(Glean.shared.getUploadEnabled()).to(beFalse())
            }
        }
    }
}

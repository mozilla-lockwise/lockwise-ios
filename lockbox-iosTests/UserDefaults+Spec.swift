/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest
import RxCocoa

@testable import Lockbox

class UserDefaultSpec: QuickSpec {
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()

    override func spec() {
        describe("onLock") {
            var lockObserver = self.scheduler.createObserver(Bool.self)

            beforeEach {
                lockObserver = self.scheduler.createObserver(Bool.self)

                UserDefaults.standard.onLock
                        .subscribe(lockObserver)
                        .disposed(by: self.disposeBag)
            }

            it("pushes new values for the SettingKey to observers") {
                UserDefaults.standard.set(true, forKey: SettingKey.locked.rawValue)

                expect(lockObserver.events.last!.value.element).to(beTrue())
            }
        }

        describe("onBiometricLockEnabled") {
            var lockObserver = self.scheduler.createObserver(Bool.self)

            beforeEach {
                lockObserver = self.scheduler.createObserver(Bool.self)

                UserDefaults.standard.onBiometricsEnabled
                        .subscribe(lockObserver)
                        .disposed(by: self.disposeBag)
            }

            it("pushes new values for the SettingKey to observers") {
                UserDefaults.standard.set(true, forKey: SettingKey.biometricLogin.rawValue)

                expect(lockObserver.events.last!.value.element).to(beTrue())
            }
        }

        describe("onAutoLockSetting") {
            var autoLockSettingObserver = self.scheduler.createObserver(AutoLockSetting.self)

            beforeEach {
                autoLockSettingObserver = self.scheduler.createObserver(AutoLockSetting.self)

                UserDefaults.standard.onAutoLockTime
                        .subscribe(autoLockSettingObserver)
                        .disposed(by: self.disposeBag)
            }

            it("pushes new values for the SettingKey to observers") {
                UserDefaults.standard.set(AutoLockSetting.OnAppExit.rawValue, forKey: SettingKey.autoLockTime.rawValue)

                expect(autoLockSettingObserver.events.last!.value.element).to(equal(AutoLockSetting.OnAppExit))
            }

            it("pushes the default value when a meaningless autolock time is set") {
                UserDefaults.standard.set("FOREVER", forKey: SettingKey.autoLockTime.rawValue)

                expect(autoLockSettingObserver.events.last!.value.element).to(equal(Constant.setting.defaultAutoLockTimeout))
            }
        }

        describe("onPreferredBrowser") {
            var preferredBrowserSettingObserver: TestableObserver<PreferredBrowserSetting>!

            beforeEach {
                preferredBrowserSettingObserver = self.scheduler.createObserver(PreferredBrowserSetting.self)
                UserDefaults.standard.onPreferredBrowser
                        .subscribe(preferredBrowserSettingObserver)
                        .disposed(by: self.disposeBag)
            }

            it("pushes new values for theSettingKey to observers") {
                UserDefaults.standard.set(PreferredBrowserSetting.Firefox.rawValue, forKey: SettingKey.preferredBrowser.rawValue)
                expect(preferredBrowserSettingObserver.events.last!.value.element).to(equal(PreferredBrowserSetting.Firefox))
            }
        }
    }
}

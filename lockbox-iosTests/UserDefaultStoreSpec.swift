/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxBlocking

@testable import Lockbox

class UserDefaultStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let registerStub = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.registerStub.asObservable()
        }
    }

    var dispatcher: FakeDispatcher!
    var subject: UserDefaultStore!

    let userDefaults = UserDefaults(suiteName: Constant.app.group)!

    override func spec() {
        describe("UserDefaultStore") {
            beforeEach {
                self.userDefaults.set(
                        Constant.setting.defaultPreferredBrowser.rawValue,
                        forKey: LocalUserDefaultKey.preferredBrowser.rawValue)
                self.userDefaults.set(
                        false,
                        forKey: LocalUserDefaultKey.recordUsageData.rawValue)
                self.userDefaults.removeObject(forKey: UserDefaultKey.autoLockTimerDate.rawValue)
                self.userDefaults.removeObject(forKey: UserDefaultKey.autoLockTime.rawValue)
                self.userDefaults.removeObject(forKey: LocalUserDefaultKey.itemListSort.rawValue)

                self.dispatcher = FakeDispatcher()
                self.subject = UserDefaultStore(dispatcher: self.dispatcher)
            }

            it("populates all nil values with the default on initialization") {
                expect(Setting.AutoLock(rawValue: self.userDefaults.value(forKey: UserDefaultKey.autoLockTime.rawValue) as! String)).to(equal(Constant.setting.defaultAutoLock))
                expect(Setting.PreferredBrowser(rawValue: self.userDefaults.value(forKey: LocalUserDefaultKey.preferredBrowser.rawValue) as! String)).to(equal(Constant.setting.defaultPreferredBrowser))
                expect(Setting.ItemListSort(rawValue: self.userDefaults.value(forKey: LocalUserDefaultKey.itemListSort.rawValue) as! String)).to(equal(Constant.setting.defaultItemListSort))
                expect(self.userDefaults.value(forKey: LocalUserDefaultKey.recordUsageData.rawValue) as? Bool).to(beFalse())
                if let sharedUserDefaults = UserDefaults(suiteName: Constant.app.group) {
                    expect(sharedUserDefaults.value(forKey: UserDefaultKey.autoLockTimerDate.rawValue)).to(beNil())
                }
            }

            describe("SettingAction.autolock") {
                let autoLockSetting = Setting.AutoLock.TwelveHours

                beforeEach {
                    self.dispatcher.registerStub.onNext(SettingAction.autoLockTime(timeout: autoLockSetting))
                }

                it("sets the appropriate value for key in userdefaults") {
                    expect(Setting.AutoLock(rawValue: self.userDefaults.value(forKey: UserDefaultKey.autoLockTime.rawValue) as! String)).to(equal(autoLockSetting))
                }
            }

            describe("SettingAction.preferredBrowser") {
                let browserSetting = Setting.PreferredBrowser.Firefox

                beforeEach {
                    self.dispatcher.registerStub.onNext(SettingAction.preferredBrowser(browser: browserSetting))
                }

                it("sets the appropriate value for key in userdefaults") {
                    expect(self.userDefaults.value(forKey: LocalUserDefaultKey.preferredBrowser.rawValue) as? String).to(equal(browserSetting.rawValue))
                }
            }

            describe("SettingAction.recordUsageData") {
                beforeEach {
                    self.dispatcher.registerStub.onNext(SettingAction.recordUsageData(enabled: false))
                }

                it("sets the appropriate value for the key in userdefaults") {
                    expect(self.userDefaults.value(forKey: LocalUserDefaultKey.recordUsageData.rawValue) as? Bool).to(beFalse())
                }
            }

            describe("SettingAction.itemListSort") {
                let itemListSort = Setting.ItemListSort.recentlyUsed

                beforeEach {
                    self.dispatcher.registerStub.onNext(SettingAction.itemListSort(sort: itemListSort))
                }

                it("sets the appropriate value for the key in userdefaults") {
                    expect(Setting.ItemListSort(rawValue: self.userDefaults.value(forKey: LocalUserDefaultKey.itemListSort.rawValue) as! String)).to(equal(itemListSort))
                }
            }

            describe("SettingAction.reset") {
                beforeEach {
                    self.dispatcher.registerStub.onNext(SettingAction.reset)
                }

                it("sets the appropriate value for key in userdefaults") {
                    expect(Setting.AutoLock(rawValue: self.userDefaults.value(forKey: UserDefaultKey.autoLockTime.rawValue) as! String)).to(equal(Constant.setting.defaultAutoLock))
                    expect(Setting.PreferredBrowser(rawValue: self.userDefaults.value(forKey: LocalUserDefaultKey.preferredBrowser.rawValue) as! String)).to(equal(Constant.setting.defaultPreferredBrowser))
                    expect(Setting.ItemListSort(rawValue: self.userDefaults.value(forKey: LocalUserDefaultKey.itemListSort.rawValue) as! String)).to(equal(Constant.setting.defaultItemListSort))
                    expect(self.userDefaults.value(forKey: LocalUserDefaultKey.recordUsageData.rawValue) as? Bool).to(beTrue())
                    if let sharedUserDefaults = UserDefaults(suiteName: Constant.app.group) {
                        expect(sharedUserDefaults.value(forKey: UserDefaultKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }
            }

            describe(".autoLockTime") {
                it("pushes the UserDefaults autolocktime value") {
                    let value = Setting.AutoLock.FifteenMinutes.rawValue
                    self.userDefaults.set(value, forKey: UserDefaultKey.autoLockTime.rawValue)
                    let time = try! self.subject.autoLockTime.toBlocking().first()!

                    expect(value).to(equal(time.rawValue))
                }
            }

            describe(".preferredBrowser") {
                it("pushes the UserDefaults preferredBrowser value") {
                    let browser = try! self.subject.preferredBrowser.toBlocking().first()!

                    expect(self.userDefaults.value(forKey: LocalUserDefaultKey.preferredBrowser.rawValue) as? String).to(equal(browser.rawValue))
                }
            }

            describe(".recordUsageData") {
                it("pushes the UserDefaults recordUsageData value") {
                    let record = try! self.subject.recordUsageData.toBlocking().first()!

                    expect(self.userDefaults.value(forKey: LocalUserDefaultKey.recordUsageData.rawValue) as? Bool).to(equal(record))
                }
            }

            describe(".itemListSort") {
                it("pushes the UserDefaults itemListSort value") {
                    let itemListSort = try! self.subject.itemListSort.toBlocking().first()!

                    expect(self.userDefaults.value(forKey: LocalUserDefaultKey.itemListSort.rawValue) as? String).to(equal(itemListSort.rawValue))
                }
            }
        }

        describe("UserDefaultKey defaults") {
            it("returns the appropriate key for userdefaults") {
                expect(UserDefaultKey.autoLockTime.defaultValue as? String).to(equal(Constant.setting.defaultAutoLock.rawValue))
                expect(LocalUserDefaultKey.preferredBrowser.defaultValue as? String).to(equal(Constant.setting.defaultPreferredBrowser.rawValue))
                expect(LocalUserDefaultKey.recordUsageData.defaultValue as? Bool).to(equal(Constant.setting.defaultRecordUsageData))
                expect(LocalUserDefaultKey.itemListSort.defaultValue as? String).to(equal(Constant.setting.defaultItemListSort.rawValue))
                expect(UserDefaultKey.autoLockTimerDate.defaultValue).to(beNil())
            }
        }
    }
}

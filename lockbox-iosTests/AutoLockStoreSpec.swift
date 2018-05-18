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

    class FakeDataStore: DataStore {
        var lockedStub = PublishSubject<Bool>()

        override var locked: Observable<Bool> {
            get {
                return self.lockedStub.asObservable()
            }
        }
    }

    class FakeDataStoreActionHandler: DataStoreActionHandler {
        var action: DataStoreAction?

        override func invoke(_ action: DataStoreAction) {
            self.action = action
        }
    }

    var dispatcher: FakeDispatcher!
    var userDefaults: UserDefaults!
    var dataStore: FakeDataStore!
    var dataStoreActionHandler: FakeDataStoreActionHandler!

    var subject: AutoLockStore!

    override func spec() {
        describe("AutoLockStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.dataStoreActionHandler = FakeDataStoreActionHandler()
                self.dataStore = FakeDataStore()
                self.userDefaults = UserDefaults.standard

                self.subject = AutoLockStore(
                        dispatcher: self.dispatcher,
                        dataStore: self.dataStore,
                        dataStoreActionHandler: self.dataStoreActionHandler,
                        userDefaults: UserDefaults.standard)
            }

            describe("backgrounding app") {
                describe("with auto lock setting on OnAppExit") {
                    beforeEach {
                        self.userDefaults.set(AutoLockSetting.OnAppExit.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                        self.dispatcher.dispatch(action: LifecycleAction.background)
                    }

                    it("locks app") {
                        expect(self.dataStoreActionHandler.action).to(equal(DataStoreAction.lock))
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
                        expect(self.dataStoreActionHandler.action).to(beNil())
                        expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }
            }

            describe("onLock setting changed") {
                describe("to unlock") {
                    describe("auto lock timer is a time interval") {
                        beforeEach {
                            self.dataStore.lockedStub.onNext(true)
                            self.userDefaults.set(AutoLockSetting.FiveMinutes.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                            self.dataStore.lockedStub.onNext(false)
                        }

                        it("sets the timer") {
                            expect(self.subject.timer).toNot(beNil())
                        }

                        it("sets the timer value from user defaults") {
                            expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).toNot(beNil())
                        }
                    }

                    it("doesn't set timer for AutoLockSetting.Never") {
                        self.dataStore.lockedStub.onNext(true)
                        self.userDefaults.set(AutoLockSetting.Never.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                        self.dataStore.lockedStub.onNext(false)
                        expect(self.subject.timer?.isValid).to(beFalsy())
                        expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).to(beNil())
                    }

                    it("doesn't set timer for AutoLockSetting.OnAppExit") {
                        self.userDefaults.set(AutoLockSetting.OnAppExit.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                        self.dataStore.lockedStub.onNext(false)
                        expect(self.subject.timer?.isValid).to(beFalsy())
                        expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }

                describe("to lock") {
                    beforeEach {
                        self.dataStore.lockedStub.onNext(true)
                    }

                    it("stops the timer") {
                        expect(self.subject.timer?.isValid).to(beFalsy())
                        expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }
            }

            describe("onAutoLockTime change") {
                var fireDate: TimeInterval?

                beforeEach {
                    self.userDefaults.set(AutoLockSetting.FiveMinutes.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                    fireDate = self.subject.timer?.fireDate.timeIntervalSince1970
                }

                describe("to Never") {
                    beforeEach {
                        self.userDefaults.set(AutoLockSetting.Never.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                    }

                    it("stops the timer") {
                        expect(self.subject.timer?.isValid).to(beFalse())
                        expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }

                describe("to OnAppExit") {
                    beforeEach {
                        self.userDefaults.set(AutoLockSetting.OnAppExit.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                    }

                    it("stops the timer") {
                        expect(self.subject.timer?.isValid).to(beFalse())
                        expect(self.userDefaults.value(forKey: SettingKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }

                describe("to different time interval") {
                    beforeEach {
                        self.userDefaults.set(AutoLockSetting.OneHour.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                    }

                    it("restarts the timer") {
                        expect(self.subject.timer).toNot(beNil())
                        let newFireDate = self.subject.timer?.fireDate.timeIntervalSince1970
                        expect(newFireDate).toNot(equal(fireDate))
                    }
                }
            }
        }
    }
}

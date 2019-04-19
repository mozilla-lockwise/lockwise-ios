/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift

@testable import Lockbox

class AutoLockSupportSpec: QuickSpec {
    class FakeUserDefaultStore: UserDefaultStore {
        let autoLockStub = PublishSubject<Setting.AutoLock>()

        override var autoLockTime: Observable<Setting.AutoLock> {
            return autoLockStub
        }
    }

    class FakeUserDefaults: UserDefaults {
        var doubleStub: Double = 0.0

        var setArg: Double?
        var setArgKey: String?
        override func set(_ value: Double, forKey defaultName: String) {
            setArg = value
            setArgKey = defaultName
        }

        override func double(forKey defaultName: String) -> Double {
            return doubleStub
        }
    }

    var userDefaultStore: FakeUserDefaultStore!
    var userDefaults: FakeUserDefaults!
    var subject: AutoLockSupport!

    override func spec() {
        describe("AutoLockSupport") {
            beforeEach {
                self.userDefaultStore = FakeUserDefaultStore()
                self.userDefaults = FakeUserDefaults()
                self.subject = AutoLockSupport(
                    userDefaultStore: self.userDefaultStore,
                    userDefaults: self.userDefaults
                )
            }

            describe("storeNextAutoLockTime") {
                beforeEach {
                    self.subject.storeNextAutolockTime()
                }

                describe("when the autolocktime is not never") {
                    let currentAutoLock = Setting.AutoLock.FifteenMinutes
                    beforeEach {
                        self.userDefaultStore.autoLockStub.onNext(currentAutoLock)
                    }

                    it("stores the next expected autolocktime") {
                        let expected = Double(currentAutoLock.seconds) + NSTimeIntervalSince1970

                        expect(self.userDefaults.setArg).to(equal(expected))
                        expect(self.userDefaults.setArgKey).to(equal(UserDefaultKey.autoLockTimerDate.rawValue))
                    }
                }

                describe("when the autolocktime is never") {
                    let currentAutoLock = Setting.AutoLock.Never
                    beforeEach {
                        self.userDefaultStore.autoLockStub.onNext(currentAutoLock)
                    }

                    it("stores double.MAX as the autolocktimerdate") {
                        let expected = Double.greatestFiniteMagnitude

                        expect(self.userDefaults.setArg).to(equal(expected))
                        expect(self.userDefaults.setArgKey).to(equal(UserDefaultKey.autoLockTimerDate.rawValue))
                    }
                }

                describe("backdate next lock time") {
                    beforeEach {
                        self.subject.backDateNextLockTime()
                    }

                    it("stores 0 as autolocktimerdate") {
                        let expected: Double = 0

                        expect(self.userDefaults.setArg).to(equal(expected))
                        expect(self.userDefaults.setArgKey).to(equal(UserDefaultKey.autoLockTimerDate.rawValue))
                    }
                }

                describe("forward date next lock time") {
                    beforeEach {
                        self.subject.forwardDateNextLockTime()
                    }

                    it("stores double.MAX as autolocktimerdate") {
                        let expected: Double = Double.greatestFiniteMagnitude

                        expect(self.userDefaults.setArg).to(equal(expected))
                        expect(self.userDefaults.setArgKey).to(equal(UserDefaultKey.autoLockTimerDate.rawValue))
                    }
                }

                describe("lockcurrentlyrequired") {
                    describe("when the autolocktimerdate is in the future") {
                        beforeEach {
                            self.userDefaults.doubleStub = Double.greatestFiniteMagnitude
                        }

                        it("notes that lock is not required") {
                            expect(self.subject.lockCurrentlyRequired).to(beFalse())
                        }
                    }

                    describe("when the autolocktimerdate is in the past") {
                        beforeEach {
                            self.userDefaults.doubleStub = 0
                        }

                        it("notes that lock is not required") {
                            expect(self.subject.lockCurrentlyRequired).to(beTrue())
                        }
                    }
                }
            }
        }
    }
}

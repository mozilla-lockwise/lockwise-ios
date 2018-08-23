/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift

@testable import Lockbox

enum AutoLockStoreSpecSharedExample: String {
    case TimerReset, TimerNotReset
}

enum AutoLockStoreSpecContext: String {
    case Action
}

class AutoLockStoreSpec: QuickSpec {

        class FakeDispatcher: Dispatcher {
            let registerStub = PublishSubject<Action>()
            var dispatchActionArgument: Action?

            override var register: Observable<Action> {
                return self.registerStub.asObservable()
            }

            override func dispatch(action: Action) {
                self.dispatchActionArgument = action
            }
        }

    class FakeDataStore: DataStore {
        let lockedStub = PublishSubject<Bool>()

        override var locked: Observable<Bool> {
            return self.lockedStub.asObservable()
        }
    }

    var dispatcher: FakeDispatcher!
    var userDefaults: UserDefaults!
    var dataStore: FakeDataStore!

    var subject: AutoLockStore!

    override func spec() {
        describe("AutoLockStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.dataStore = FakeDataStore()
                self.userDefaults = UserDefaults(suiteName: Constant.app.group)

                self.subject = AutoLockStore(
                        dispatcher: self.dispatcher,
                        dataStore: self.dataStore,
                        userDefaults: self.userDefaults)
            }

            describe("foregrounding app") {
                describe("when the app is on a webview") {
                    beforeEach {
                        self.userDefaults.set((Date().timeIntervalSince1970 - 3), forKey: UserDefaultKey.autoLockTimerDate.rawValue)
                        self.userDefaults.set(Setting.AutoLock.FiveMinutes.rawValue, forKey: UserDefaultKey.autoLockTime.rawValue)
                        self.dispatcher.registerStub.onNext(ExternalWebsiteRouteAction(urlString: "www.mozilla.org", title: "moz", returnRoute: MainRouteAction.list))
                        self.dispatcher.registerStub.onNext(LifecycleAction.foreground)
                    }

                    it("locks the app") {
                        expect(self.dispatcher.dispatchActionArgument as? DataStoreAction).to(equal(DataStoreAction.lock))
                        expect(self.userDefaults.value(forKey: UserDefaultKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }

                describe("when the app is not on a webview") {
                    beforeEach {
                        self.userDefaults.set((Date().timeIntervalSince1970 - 3), forKey: UserDefaultKey.autoLockTimerDate.rawValue)
                        self.userDefaults.set(Setting.AutoLock.FiveMinutes.rawValue, forKey: UserDefaultKey.autoLockTime.rawValue)
                        self.dispatcher.registerStub.onNext(LifecycleAction.foreground)
                    }

                    it("locks the app") {
                        expect(self.dispatcher.dispatchActionArgument as? DataStoreAction).to(equal(DataStoreAction.lock))
                        expect(self.userDefaults.value(forKey: UserDefaultKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }
            }

            describe("onLock setting changed") {
                describe("to unlock") {
                    describe("auto lock timer is a time interval") {
                        beforeEach {
                            self.dataStore.lockedStub.onNext(true)
                            self.userDefaults.set(Setting.AutoLock.FiveMinutes.rawValue, forKey: UserDefaultKey.autoLockTime.rawValue)
                            self.dataStore.lockedStub.onNext(false)
                        }

                        it("sets the timer") {
                            expect(self.subject.timer).toNot(beNil())
                        }

                        it("sets the timer value from user defaults") {
                            expect(self.userDefaults.value(forKey: UserDefaultKey.autoLockTimerDate.rawValue)).toNot(beNil())
                        }
                    }

                    it("doesn't set timer for Setting.AutoLock.Never") {
                        self.dataStore.lockedStub.onNext(true)
                        self.userDefaults.set(Setting.AutoLock.Never.rawValue, forKey: UserDefaultKey.autoLockTime.rawValue)
                        self.dataStore.lockedStub.onNext(false)
                        expect(self.subject.timer?.isValid).to(beFalsy())
                        expect(self.userDefaults.value(forKey: UserDefaultKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }

                describe("to lock") {
                    beforeEach {
                        self.dataStore.lockedStub.onNext(true)
                    }

                    it("stops the timer") {
                        expect(self.subject.timer?.isValid).to(beFalsy())
                        expect(self.userDefaults.value(forKey: UserDefaultKey.autoLockTimerDate.rawValue)).to(beNil())
                    }
                }
            }

            describe("on any user interaction") {
                var fireDate: TimeInterval?

                beforeEach {
                    self.userDefaults.set(Setting.AutoLock.FiveMinutes.rawValue, forKey: UserDefaultKey.autoLockTime.rawValue)
                    self.dispatcher.registerStub.onNext(SettingAction.autoLockTime(timeout: .FiveMinutes))
                    fireDate = self.subject.timer?.fireDate.timeIntervalSince1970
                }

                describe("autolocksetting specifically") {
                    describe("to Never") {
                        beforeEach {
                            self.userDefaults.set(Setting.AutoLock.Never.rawValue, forKey: UserDefaultKey.autoLockTime.rawValue)
                            self.dispatcher.registerStub.onNext(SettingAction.autoLockTime(timeout: .Never))
                        }

                        it("stops the timer") {
                            expect(self.subject.timer?.isValid).to(beFalse())
                            expect(self.userDefaults.value(forKey: UserDefaultKey.autoLockTimerDate.rawValue)).to(beNil())
                        }
                    }

                    describe("to different time interval") {
                        beforeEach {
                            self.userDefaults.set(Setting.AutoLock.OneHour.rawValue, forKey: UserDefaultKey.autoLockTime.rawValue)
                            self.dispatcher.registerStub.onNext(SettingAction.autoLockTime(timeout: .OneHour))
                        }

                        it("restarts the timer") {
                            expect(self.subject.timer).toNot(beNil())
                            let newFireDate = self.subject.timer?.fireDate.timeIntervalSince1970
                            expect(newFireDate).toNot(equal(fireDate))
                        }
                    }
                }

                describe("autolock pauses on going to an FAQ or feedback page") {
                    beforeEach {
                        let action = ExternalWebsiteRouteAction(urlString: "https://example.com", title: "Feedback form", returnRoute: SettingRouteAction.list)
                        self.dispatcher.dispatch(action: action)
                    }
                    it("resets the timer, but does not clear the fireDate") {
                        let newFireDate = self.userDefaults.double(forKey: UserDefaultKey.autoLockTimerDate.rawValue)
                        expect(newFireDate).to(equal(fireDate))
                    }
                }

                describe("miscellaneous actions") {
                    sharedExamples(AutoLockStoreSpecSharedExample.TimerReset.rawValue) { context in
                        it("resets the timer") {
                            let action = context()[AutoLockStoreSpecContext.Action.rawValue] as! Action
                            self.dispatcher.registerStub.onNext(action)
                            expect(self.subject.timer).toNot(beNil())
                            let newFireDate = self.subject.timer?.fireDate.timeIntervalSince1970
                            expect(newFireDate).toNot(equal(fireDate))
                        }
                    }

                    itBehavesLike(AutoLockStoreSpecSharedExample.TimerReset.rawValue) {
                        [AutoLockStoreSpecContext.Action.rawValue: MainRouteAction.list]
                    }

                    itBehavesLike(AutoLockStoreSpecSharedExample.TimerReset.rawValue) {
                        [AutoLockStoreSpecContext.Action.rawValue: SettingRouteAction.list]
                    }

                    itBehavesLike(AutoLockStoreSpecSharedExample.TimerReset.rawValue) {
                        [AutoLockStoreSpecContext.Action.rawValue: CopyAction(text: "something", field: CopyField.username, itemID: "wfewefsd")]
                    }

                    itBehavesLike(AutoLockStoreSpecSharedExample.TimerReset.rawValue) {
                        [AutoLockStoreSpecContext.Action.rawValue: ExternalLinkAction(baseURLString: "www.example.com")]
                    }

                    itBehavesLike(AutoLockStoreSpecSharedExample.TimerReset.rawValue) {
                        [AutoLockStoreSpecContext.Action.rawValue: ItemDetailDisplayAction.togglePassword(displayed: true)]
                    }

                    itBehavesLike(AutoLockStoreSpecSharedExample.TimerReset.rawValue) {
                        [AutoLockStoreSpecContext.Action.rawValue: SettingAction.preferredBrowser(browser: .Focus)]
                    }
                }

                describe("non-user-interaction actions") {
                    sharedExamples(AutoLockStoreSpecSharedExample.TimerNotReset.rawValue) { context in
                        it("does not reset the timer") {
                            let action = context()[AutoLockStoreSpecContext.Action.rawValue] as! Action
                            self.dispatcher.registerStub.onNext(action)
                            expect(self.subject.timer).toNot(beNil())
                            let newFireDate = self.subject.timer?.fireDate.timeIntervalSince1970
                            expect(newFireDate).to(equal(fireDate))
                        }
                    }

                    itBehavesLike(AutoLockStoreSpecSharedExample.TimerNotReset.rawValue) {
                        [AutoLockStoreSpecContext.Action.rawValue: DataStoreAction.lock]
                    }

                    itBehavesLike(AutoLockStoreSpecSharedExample.TimerNotReset.rawValue) {
                        [AutoLockStoreSpecContext.Action.rawValue: AccountAction.clear]
                    }
                }
            }
        }
    }
}

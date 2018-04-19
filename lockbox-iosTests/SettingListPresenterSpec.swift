/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift
import RxCocoa

@testable import Lockbox

class SettingsPresenterSpec: QuickSpec {
    class FakeSettingsView: SettingListViewProtocol {
        var itemsObserver: TestableObserver<[SettingSectionModel]>!
        var fakeButtonPress = PublishSubject<Void>()

        private let disposeBag = DisposeBag()

        func bind(items: SharedSequence<DriverSharingStrategy, [SettingSectionModel]>) {
            items.drive(itemsObserver).disposed(by: disposeBag)
        }

        var onSignOut: ControlEvent<Void> {
            return ControlEvent(events: fakeButtonPress.asObservable())
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var routeActionArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.routeActionArgument = action
        }
    }

    class FakeSettingActionHandler: SettingActionHandler {
        var actionArgument: SettingAction?

        override func invoke(_ action: SettingAction) {
            actionArgument = action
        }
    }

    class FakeBiometryManager: BiometryManager {
        var touchIdStub: Bool!
        var faceIdStub: Bool!

        override var usesTouchID: Bool {
            return self.touchIdStub
        }

        override var usesFaceID: Bool {
            return self.faceIdStub
        }
    }

    private var view: FakeSettingsView!
    private var routeActionHandler: FakeRouteActionHandler!
    private var settingActionHandler: FakeSettingActionHandler!
    private var biometryManager: FakeBiometryManager!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()

    var subject: SettingListPresenter!

    override func spec() {
        describe("SettingsPresenter") {
            beforeEach {
                self.view = FakeSettingsView()
                self.view.itemsObserver = self.scheduler.createObserver([SettingSectionModel].self)

                self.routeActionHandler = FakeRouteActionHandler()
                self.settingActionHandler = FakeSettingActionHandler()
                self.biometryManager = FakeBiometryManager()

                self.subject = SettingListPresenter(view: self.view,
                        routeActionHandler: self.routeActionHandler,
                        settingActionHandler: self.settingActionHandler,
                        biometryManager: self.biometryManager)
            }

            describe("onViewReady") {
                describe("biometrics field") {
                    describe("when the user has not given the app access to touchID or faceID") {
                        beforeEach {
                            self.biometryManager.faceIdStub = false
                            self.biometryManager.touchIdStub = false

                            UserDefaults.standard.set(true, forKey: SettingKey.biometricLogin.rawValue)
                            UserDefaults.standard.set(AutoLockSetting.OneHour.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                            self.subject.onViewReady()
                        }

                        it("doesn't show the biometric setting") {
                            let userAccountSettings = self.view.itemsObserver.events.last!.value.element![1].items

                            expect(userAccountSettings.filter { item -> Bool in
                                return item is SwitchSettingCellConfiguration
                            }.count).to(equal(0))
                        }
                    }

                    describe("when the user has given the app access to faceID") {
                        beforeEach {
                            self.biometryManager.faceIdStub = true
                            self.biometryManager.touchIdStub = true

                            UserDefaults.standard.set(true, forKey: SettingKey.biometricLogin.rawValue)
                            UserDefaults.standard.set(AutoLockSetting.OneHour.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                            self.subject.onViewReady()
                        }

                        it("respects biometricsEnabled stored value & sets the title appropriately") {
                            let biometricCellConfig = self.view.itemsObserver.events.last!.value.element![1].items[1] as! SwitchSettingCellConfiguration
                            expect(biometricCellConfig.text).to(equal(Constant.string.settingsFaceId))
                            expect(biometricCellConfig.isOn).to(beTrue())
                        }
                    }

                    describe("when the user has given the app access to touchID but not faceID") {
                        beforeEach {
                            self.biometryManager.faceIdStub = false
                            self.biometryManager.touchIdStub = true

                            UserDefaults.standard.set(false, forKey: SettingKey.biometricLogin.rawValue)
                            UserDefaults.standard.set(AutoLockSetting.OneHour.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                            self.subject.onViewReady()
                        }

                        it("respects biometricsEnabled stored value & sets the title appropriately") {
                            let biometricCellConfig = self.view.itemsObserver.events.last!.value.element![1].items[1] as! SwitchSettingCellConfiguration
                            expect(biometricCellConfig.text).to(equal(Constant.string.settingsTouchId))
                            expect(biometricCellConfig.isOn).to(beFalse())
                        }
                    }
                }

                describe("onSignOut") {
                    beforeEach {
                        self.biometryManager.faceIdStub = false
                        self.biometryManager.touchIdStub = true
                        self.subject.onViewReady()
                        self.view.fakeButtonPress.onNext(())
                    }

                    it("locks the application and routes to the login flow") {
                        expect(self.settingActionHandler.actionArgument).to(equal(SettingAction.visualLock(locked: true)))
                        let argument = self.routeActionHandler.routeActionArgument as! LoginRouteAction
                        expect(argument).to(equal(LoginRouteAction.welcome))
                    }
                }

                describe("autolock field") {
                    beforeEach {
                        self.biometryManager.faceIdStub = false
                        self.biometryManager.touchIdStub = true

                        UserDefaults.standard.set(true, forKey: SettingKey.biometricLogin.rawValue)
                        UserDefaults.standard.set(AutoLockSetting.OneHour.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                        self.subject.onViewReady()
                    }

                    it("sets detail value for autolock") {
                        let autoLockCellConfig = self.view.itemsObserver.events.last!.value.element![1].items[2]
                        expect(autoLockCellConfig.detailText).to(equal(Constant.string.autoLockOneHour))
                    }
                }
            }

            describe("onSwitch changing") {
                beforeEach {
                    self.subject.switchChanged(row: 4, isOn: true)
                }

                it("dipatches the biometriclogin enabled action") {
                    expect(self.settingActionHandler.actionArgument).to(equal(SettingAction.biometricLogin(enabled: true)))
                }
            }

            describe("onDone") {
                beforeEach {
                    let voidObservable = self.scheduler.createColdObservable([next(50, ())])

                    voidObservable
                            .bind(to: self.subject.onDone)
                            .disposed(by: self.disposeBag)

                    self.scheduler.start()
                }

                it("invokes the main list action") {
                    let argument = self.routeActionHandler.routeActionArgument as! MainRouteAction
                    expect(argument).to(equal(MainRouteAction.list))
                }
            }

            describe("onSettingCellTapped") {
                describe("when the cell has a route action") {
                    let action = SettingRouteAction.account

                    beforeEach {
                        let settingRouteObservable = self.scheduler.createColdObservable([next(50, action)])

                        settingRouteObservable
                                .bind(to: self.subject.onSettingCellTapped)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("invokes the setting route action") {
                        let argument = self.routeActionHandler.routeActionArgument as! SettingRouteAction
                        expect(argument).to(equal(action))
                    }
                }

                describe("when the cell did not have a route action") {
                    beforeEach {
                        let settingRouteObservable: Observable<SettingRouteAction?> = self.scheduler.createColdObservable([next(50, nil)]).asObservable()

                        settingRouteObservable
                                .bind(to: self.subject.onSettingCellTapped)
                                .disposed(by: self.disposeBag)

                        self.scheduler.start()
                    }

                    it("does nothing") {
                        expect(self.routeActionHandler.routeActionArgument).to(beNil())
                    }
                }
            }
        }
    }
}

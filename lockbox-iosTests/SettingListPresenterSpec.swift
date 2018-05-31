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
        var lockNowObserver: TestableObserver<Bool>!

        private let disposeBag = DisposeBag()

        func bind(items: SharedSequence<DriverSharingStrategy, [SettingSectionModel]>) {
            items.drive(itemsObserver).disposed(by: disposeBag)
        }

        var onSignOut: ControlEvent<Void> {
            return ControlEvent(events: fakeButtonPress.asObservable())
        }

        var hideLockNow: AnyObserver<Bool> {
            return self.lockNowObserver.asObserver()
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

    class FakeDataStoreActionHandler: DataStoreActionHandler {
        var actionArgument: DataStoreAction?

        override func invoke(_ action: DataStoreAction) {
            self.actionArgument = action
        }
    }

    class FakeBiometryManager: BiometryManager {
        var deviceAuthAvailableStub: Bool!

        override var deviceAuthenticationAvailable: Bool {
            return self.deviceAuthAvailableStub
        }
    }

    private var view: FakeSettingsView!
    private var routeActionHandler: FakeRouteActionHandler!
    private var settingActionHandler: FakeSettingActionHandler!
    private var dataStoreActionHandler: FakeDataStoreActionHandler!
    private var biometryManager: FakeBiometryManager!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()

    var subject: SettingListPresenter!

    override func spec() {
        describe("SettingsPresenter") {
            beforeEach {
                self.view = FakeSettingsView()
                self.view.itemsObserver = self.scheduler.createObserver([SettingSectionModel].self)
                self.view.lockNowObserver = self.scheduler.createObserver(Bool.self)

                self.routeActionHandler = FakeRouteActionHandler()
                self.settingActionHandler = FakeSettingActionHandler()
                self.dataStoreActionHandler = FakeDataStoreActionHandler()
                self.biometryManager = FakeBiometryManager()

                self.subject = SettingListPresenter(view: self.view,
                        routeActionHandler: self.routeActionHandler,
                        settingActionHandler: self.settingActionHandler,
                        dataStoreActionHandler: self.dataStoreActionHandler,
                        biometryManager: self.biometryManager)
            }

            describe("onViewReady") {
                describe("when device auth is available") {
                    beforeEach {
                        self.biometryManager.deviceAuthAvailableStub = true
                    }

                    it("shows the lock now button") {
                        self.subject.onViewReady()
                        expect(self.view.lockNowObserver.events.last!.value.element).to(beFalse())
                    }

                    describe("onSignOut") {
                        beforeEach {
                            self.subject.onViewReady()
                            self.view.fakeButtonPress.onNext(())
                        }

                        it("locks the application and routes to the login flow") {
                            expect(self.dataStoreActionHandler.actionArgument).to(equal(DataStoreAction.lock))
                            let argument = self.routeActionHandler.routeActionArgument as! LoginRouteAction
                            expect(argument).to(equal(LoginRouteAction.welcome))
                        }
                    }

                    describe("detail values on view modules") {
                        beforeEach {
                            UserDefaults.standard.set(AutoLockSetting.OneHour.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                            UserDefaults.standard.set(PreferredBrowserSetting.Focus.rawValue, forKey: SettingKey.preferredBrowser.rawValue)
                            self.subject.onViewReady()
                        }

                        it("sets detail value for autolock") {
                            let autoLockCellConfig = self.view.itemsObserver.events.last!.value.element![1].items[1]
                            expect(autoLockCellConfig.detailText).to(equal(Constant.string.autoLockOneHour))
                        }

                        it("sets detail value for preferred browser") {
                            let preferredBrowserCellConfig = self.view.itemsObserver.events.last!.value.element![1].items[2]
                            expect(preferredBrowserCellConfig.detailText).to(equal(PreferredBrowserSetting.Focus.toString()))
                        }
                    }
                }

                describe("when device auth is not available") {
                    beforeEach {
                        self.biometryManager.deviceAuthAvailableStub = false
                    }

                    it("hides the Lock Now button") {
                        self.subject.onViewReady()
                        expect(self.view.lockNowObserver.events.last!.value.element).to(beTrue())
                    }

                    describe("detail values on view modules") {
                        beforeEach {
                            UserDefaults.standard.set(AutoLockSetting.OneHour.rawValue, forKey: SettingKey.autoLockTime.rawValue)
                            UserDefaults.standard.set(PreferredBrowserSetting.Focus.rawValue, forKey: SettingKey.preferredBrowser.rawValue)
                            self.subject.onViewReady()
                        }

                        it("does not show autolock") {
                            expect(self.view.itemsObserver.events.last!.value.element![1].items.count).to(equal(2))
                        }

                        it("sets detail value for preferred browser") {
                            let preferredBrowserCellConfig = self.view.itemsObserver.events.last!.value.element![1].items[1]
                            expect(preferredBrowserCellConfig.detailText).to(equal(PreferredBrowserSetting.Focus.toString()))
                        }
                    }
                }

            }

            describe("onUsageDataSettingChanged") {
                beforeEach {
                    let voidObservable = self.scheduler.createColdObservable([next(50, false)])

                    voidObservable
                        .bind(to: self.subject.onUsageDataSettingChanged)
                        .disposed(by: self.disposeBag)

                    self.scheduler.start()
                }

                it("calls settingActionHandler") {
                    expect(self.settingActionHandler.actionArgument).to(equal(SettingAction.recordUsageData(enabled: false)))
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
                let routeActionStub = PublishSubject<RouteAction?>()
                describe("when the cell has a route action") {
                    let action = SettingRouteAction.account

                    beforeEach {
                        routeActionStub.asObservable()
                                .bind(to: self.subject.onSettingCellTapped)
                                .disposed(by: self.disposeBag)

                        routeActionStub.onNext(action)
                    }

                    it("invokes the setting route action") {
                        let argument = self.routeActionHandler.routeActionArgument as! SettingRouteAction
                        expect(argument).to(equal(action))
                    }
                }

                describe("when the cell did not have a route action") {
                    beforeEach {
                        let settingRouteObservable: Observable<RouteAction?> = self.scheduler.createColdObservable([next(50, nil)]).asObservable()

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

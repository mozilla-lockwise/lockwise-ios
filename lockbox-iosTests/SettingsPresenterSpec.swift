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
    class FakeSettingsView: SettingsProtocol {
        var itemsObserver: TestableObserver<[SettingSectionModel]>!
        private let disposeBag = DisposeBag()

        func bind(items: SharedSequence<DriverSharingStrategy, [SettingSectionModel]>) {
            items.drive(itemsObserver).disposed(by: disposeBag)
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

    private var view: FakeSettingsView!
    private var routeActionHandler: FakeRouteActionHandler!
    private var settingActionHandler: FakeSettingActionHandler!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()

    var subject: SettingsPresenter!

    override func spec() {
        describe("SettingsPresenter") {
            beforeEach {
                self.view = FakeSettingsView()
                self.view.itemsObserver = self.scheduler.createObserver([SettingSectionModel].self)

                self.routeActionHandler = FakeRouteActionHandler()
                self.settingActionHandler = FakeSettingActionHandler()

                self.subject = SettingsPresenter(view: self.view,
                                            routeActionHandler: self.routeActionHandler,
                                            settingActionHandler: self.settingActionHandler)
            }

            describe("onViewReady") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("biometrics field") {
                    it("respects biometricsEnabled stored value") {
                        UserDefaults.standard.set(true, forKey: SettingKey.biometricLogin.rawValue)

                        let biometricCellConfig = self.view.itemsObserver.events.last!.value.element![1].items[1] as! SwitchSettingCellConfiguration
                        expect(biometricCellConfig.isOn).to(beTrue())
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

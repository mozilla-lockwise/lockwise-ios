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

    var subject: SettingsPresenter!

    override func spec() {
        describe("SettingsPresenter") {
            beforeEach {
                self.view = FakeSettingsView()
                self.routeActionHandler = FakeRouteActionHandler()
                self.settingActionHandler = FakeSettingActionHandler()

                self.subject = SettingsPresenter(view: self.view,
                                            routeActionHandler: self.routeActionHandler,
                                            settingActionHandler: self.settingActionHandler)
            }

            describe("biometrics field") {
                it("respects biometricsEnabled stored value") {
                    UserDefaults.standard.set(true, forKey: SettingKey.biometricLogin.rawValue)

                    if let cellConfig = self.subject.settings.value[1].items[1] as? SwitchSettingCellConfiguration {
                        expect(cellConfig.isOn).to(beTrue())
                    } else {
                        fail("could not retreive biometricsEnabled setting")
                    }
                }
            }

            it("delivers driver onViewReady") {
                self.view.itemsObserver = self.scheduler.createObserver([SettingSectionModel].self)
                self.subject.onViewReady()
                if let settings = self.view.itemsObserver.events.last?.value.element {
                    expect(settings.count).to(be(2))
                    expect(settings[0].items.count).to(be(3))
                    expect(settings[1].items.count).to(be(3))
                } else {
                    fail("settings not set in onViewReady")
                }
            }

            it("calls handler when switch changes") {
                self.subject.switchChanged(row: 4, isOn: true)
                expect(self.settingActionHandler.actionArgument).to(equal(SettingAction.biometricLogin(enabled: true)))
            }

            it("handles action when item is selected") {
                self.subject.itemSelectedObserver.onNext(SettingCellConfiguration(text: "Auto Lock", routeAction: SettingRouteAction.autoLock))
                expect(self.routeActionHandler.routeActionArgument as? SettingRouteAction).to(equal(SettingRouteAction.autoLock))
            }

            it("does not call action handler when there is no action") {
                self.subject.itemSelectedObserver.onNext(SettingCellConfiguration(text: "Fake Item", routeAction: nil))
                expect(self.routeActionHandler.routeActionArgument).to(beNil())
            }
        }
    }
}

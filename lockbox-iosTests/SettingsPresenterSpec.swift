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

    class FakeUserInfoStore: UserInfoStore {
        let biometricsEnabledSubject = PublishSubject<Bool?>()

        override var biometricLoginEnabled: Observable<Bool?> {
            return biometricsEnabledSubject.asObservable()
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var routeActionArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.routeActionArgument = action
        }
    }

    class FakeUserInfoActionHandler: UserInfoActionHandler {
        var actionArgument: UserInfoAction?
        override func invoke(_ action: UserInfoAction) {
            actionArgument = action
        }
    }

    private var view: FakeSettingsView!
    private var userInfoStore: FakeUserInfoStore!
    private var routeActionHandler: FakeRouteActionHandler!
    private var userInfoActionHandler: FakeUserInfoActionHandler!
    private var scheduler = TestScheduler(initialClock: 0)

    var subject: SettingsPresenter!

    override func spec() {
        describe("SettingsPresenter") {
            beforeEach {
                self.view = FakeSettingsView()
                self.userInfoStore = FakeUserInfoStore()
                self.routeActionHandler = FakeRouteActionHandler()
                self.userInfoActionHandler = FakeUserInfoActionHandler()

                self.subject = SettingsPresenter(view: self.view,
                                            userInfoStore: self.userInfoStore,
                                            routeActionHandler: self.routeActionHandler,
                                            userInfoActionHandler: self.userInfoActionHandler)
            }

            describe("biometrics field") {
                it("requests biometricsEnabled field on init") {
                    expect(self.userInfoStore.biometricsEnabledSubject.hasObservers).to(beTrue())
                }

                it("respects biometricsEnabled stored value") {
                    self.userInfoStore.biometricsEnabledSubject.onNext(true)
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
                expect(self.userInfoActionHandler.actionArgument).to(equal(UserInfoAction.biometricLogin(enabled: true)))
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

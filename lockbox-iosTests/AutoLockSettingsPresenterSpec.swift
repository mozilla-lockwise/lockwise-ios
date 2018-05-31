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

class AutoLockSettingsPresenterSpec: QuickSpec {
    class FakeAutoLockSettingsView: AutoLockSettingViewProtocol {
        var itemsObserver: TestableObserver<[AutoLockSettingSectionModel]>!
        private let disposeBag = DisposeBag()

        func bind(items: SharedSequence<DriverSharingStrategy, [AutoLockSettingSectionModel]>) {
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

    private var view: FakeAutoLockSettingsView!
    private var routeActionHandler: FakeRouteActionHandler!
    private var settingActionHandler: FakeSettingActionHandler!
    private var scheduler = TestScheduler(initialClock: 0)

    var subject: AutoLockSettingPresenter!

    override func spec() {
        beforeEach {
            self.view = FakeAutoLockSettingsView()
            self.routeActionHandler = FakeRouteActionHandler()
            self.settingActionHandler = FakeSettingActionHandler()

            self.subject = AutoLockSettingPresenter(view: self.view,
                                             routeActionHandler: self.routeActionHandler,
                                             settingActionHandler: self.settingActionHandler)
        }

        it("delivers updated values when autoLock setting changes") {
            self.view.itemsObserver = self.scheduler.createObserver([AutoLockSettingSectionModel].self)
            self.subject.onViewReady()

            UserDefaults.standard.set(AutoLockSetting.FiveMinutes.rawValue, forKey: SettingKey.autoLockTime.rawValue)

            if let settings = self.view.itemsObserver.events.last?.value.element {
                for item in settings[0].items {
                    if item.valueWhenChecked as? AutoLockSetting == AutoLockSetting.FiveMinutes {
                        expect(item.isChecked).to(beTrue())
                    } else {
                        expect(item.isChecked).to(beFalse())
                    }
                }
                expect(settings.count).to(be(1))
                expect(settings[0].items.count).to(be(6))
            } else {
                fail("settings not set in onViewReady")
            }
        }

        it("calls handler when item is selected") {
            self.subject.itemSelectedObserver.onNext(AutoLockSetting.OneHour)
            expect(self.settingActionHandler.actionArgument).to(equal(SettingAction.autoLockTime(timeout: AutoLockSetting.OneHour)))
        }
    }
}

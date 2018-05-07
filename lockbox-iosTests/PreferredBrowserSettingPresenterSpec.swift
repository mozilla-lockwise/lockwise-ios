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

class PreferredBrowserSettingPresenterSpec: QuickSpec {
    class FakePreferredBrowserView: PreferredBrowserSettingViewProtocol {
        var itemsObserver: TestableObserver<[PreferredBrowserSettingSectionModel]>!
        private let disposeBag = DisposeBag()

        func bind(items: SharedSequence<DriverSharingStrategy, [PreferredBrowserSettingSectionModel]>) {
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

    var view: FakePreferredBrowserView!
    var subject: PreferredBrowserSettingPresenter!
    var userDefaults: UserDefaults = UserDefaults.standard
    var routeActionHandler: FakeRouteActionHandler!
    var settingActionHandler: FakeSettingActionHandler!
    var scheduler = TestScheduler(initialClock: 0)

    override func spec() {
        beforeEach {
            self.view = FakePreferredBrowserView()
            self.routeActionHandler = FakeRouteActionHandler()
            self.settingActionHandler = FakeSettingActionHandler()
            self.subject = PreferredBrowserSettingPresenter(view: self.view, userDefaults: self.userDefaults, routeActionHandler: self.routeActionHandler, settingActionHandler: self.settingActionHandler)
        }

        it("delivers updated values when user default value changes") {
            self.view.itemsObserver = self.scheduler.createObserver([PreferredBrowserSettingSectionModel].self)
            self.subject.onViewReady()

            UserDefaults.standard.set(PreferredBrowserSetting.Firefox.rawValue, forKey: SettingKey.preferredBrowser.rawValue)

            if let settings = self.view.itemsObserver.events.last?.value.element {
                expect(settings.count).to(be(1))
                expect(settings[0].items.count).to(be(4))

                for item in settings[0].items {
                    if item.valueWhenChecked as? PreferredBrowserSetting == PreferredBrowserSetting.Firefox {
                        expect(item.isChecked).to(beTrue())
                    } else {
                        expect(item.isChecked).to(beFalse())
                    }
                }
            } else {
                fail("settings not set in onViewReady")
            }
        }
    }
}

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

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    class FakeUserDefaultStore: UserDefaultStore {
        let autoLockStub = PublishSubject<Setting.AutoLock>()

        override var autoLockTime: Observable<Setting.AutoLock> {
            return self.autoLockStub.asObservable()
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var routeActionArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.routeActionArgument = action
        }
    }

    private var view: FakeAutoLockSettingsView!
    private var dispatcher: FakeDispatcher!
    private var userDefaultStore: FakeUserDefaultStore!
    private var routeActionHandler: FakeRouteActionHandler!
    private var scheduler = TestScheduler(initialClock: 0)

    var subject: AutoLockSettingPresenter!

    override func spec() {
        beforeEach {
            self.view = FakeAutoLockSettingsView()
            self.dispatcher = FakeDispatcher()
            self.routeActionHandler = FakeRouteActionHandler()
            self.userDefaultStore = FakeUserDefaultStore()

            self.subject = AutoLockSettingPresenter(
                    view: self.view,
                    dispatcher: self.dispatcher,
                    userDefaultStore: self.userDefaultStore,
                    routeActionHandler: self.routeActionHandler)
        }

        it("delivers updated values when autoLock setting changes") {
            self.view.itemsObserver = self.scheduler.createObserver([AutoLockSettingSectionModel].self)
            self.subject.onViewReady()

            self.userDefaultStore.autoLockStub.onNext(Setting.AutoLock.FiveMinutes)

            if let settings = self.view.itemsObserver.events.last?.value.element {
                for item in settings[0].items {
                    if item.valueWhenChecked as? Setting.AutoLock == Setting.AutoLock.FiveMinutes {
                        expect(item.isChecked).to(beTrue())
                    } else {
                        expect(item.isChecked).to(beFalse())
                    }
                }
                expect(settings.count).to(be(1))
                expect(settings[0].items.count).to(be(8))
            } else {
                fail("settings not set in onViewReady")
            }
        }

        it("calls handler when item is selected") {
            self.subject.itemSelectedObserver.onNext(Setting.AutoLock.OneHour)
            let action = self.dispatcher.dispatchedActions.last as! SettingAction
            expect(action).to(equal(SettingAction.autoLockTime(timeout: Setting.AutoLock.OneHour)))
        }
    }
}

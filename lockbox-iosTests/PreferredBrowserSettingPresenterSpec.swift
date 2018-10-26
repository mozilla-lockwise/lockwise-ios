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
        var fakeOnSettingsButtonPressed = PublishSubject<Void>()
        private let disposeBag = DisposeBag()

        func bind(items: SharedSequence<DriverSharingStrategy, [PreferredBrowserSettingSectionModel]>) {
            items.drive(itemsObserver).disposed(by: disposeBag)
        }
        
        var onSettingsButtonPressed: ControlEvent<Void>? {
            return ControlEvent<Void>(events: fakeOnSettingsButtonPressed.asObservable())
        }
        
    }

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    class FakeUserDefaultStore: UserDefaultStore {
        var preferredBrowserStub = PublishSubject<Setting.PreferredBrowser>()

        override var preferredBrowser: Observable<Setting.PreferredBrowser> {
            return self.preferredBrowserStub.asObservable()
        }
    }

    var subject: PreferredBrowserSettingPresenter!
    var view: FakePreferredBrowserView!
    var dispatcher: FakeDispatcher!
    var userDefaultStore: FakeUserDefaultStore!
    var scheduler = TestScheduler(initialClock: 0)

    override func spec() {
        beforeEach {
            self.view = FakePreferredBrowserView()
            self.dispatcher = FakeDispatcher()
            self.userDefaultStore = FakeUserDefaultStore()
            self.subject = PreferredBrowserSettingPresenter(
                    view: self.view,
                    dispatcher: self.dispatcher,
                    userDefaultStore: self.userDefaultStore
            )
        }

        it("delivers updated values when user default value changes") {
            self.view.itemsObserver = self.scheduler.createObserver([PreferredBrowserSettingSectionModel].self)
            self.subject.onViewReady()

            self.userDefaultStore.preferredBrowserStub.onNext(Setting.PreferredBrowser.Firefox)

            if let settings = self.view.itemsObserver.events.last?.value.element {
                expect(settings.count).to(be(1))
                expect(settings[0].items.count).to(be(3))

                for item in settings[0].items {
                    if item.valueWhenChecked as? Setting.PreferredBrowser == Setting.PreferredBrowser.Firefox {
                        expect(item.isChecked).to(beTrue())
                    } else {
                        expect(item.isChecked).to(beFalse())
                    }
                }
            } else {
                fail("settings not set in onViewReady")
            }
        }

        it("onSettingsTap routes to settings") {
            self.subject.onSettingsTap.onNext(())
            let route = self.dispatcher.dispatchedActions.last as! SettingRouteAction
            expect(route).to(equal(SettingRouteAction.list))
        }
        
        describe("settings button") {
            beforeEach {
                self.view.itemsObserver = self.scheduler.createObserver([PreferredBrowserSettingSectionModel].self)
                self.subject.onViewReady()
                self.view.fakeOnSettingsButtonPressed.onNext(())
            }
            
            it("dispatches the setting route action") {
                let action = self.dispatcher.dispatchedActions.popLast() as! SettingRouteAction
                expect(action).to(equal(.list))
            }
        }
    }
}

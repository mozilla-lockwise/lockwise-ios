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

class SettingListPresenterSpec: QuickSpec {
    class FakeSettingsView: SettingListViewProtocol {

        var displayAlertControllerCalled = false
        var displayAlertControllerButtons: [AlertActionButtonConfiguration]?
        func displayAlertController(buttons: [AlertActionButtonConfiguration], title: String?, message: String?, style: UIAlertController.Style) {
            displayAlertControllerCalled = true
            displayAlertControllerButtons = buttons
        }

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

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    class FakeUserDefaultStore: UserDefaultStore {
        let autoLockStub = PublishSubject<Setting.AutoLock>()
        let preferredBrowserStub = PublishSubject<Setting.PreferredBrowser>()
        let recordUsageDataStub = PublishSubject<Bool>()

        override var autoLockTime: Observable<Setting.AutoLock> {
            return self.autoLockStub.asObservable()
        }

        override var preferredBrowser: Observable<Setting.PreferredBrowser> {
            return self.preferredBrowserStub.asObservable()
        }

        override var recordUsageData: Observable<Bool> {
            return self.recordUsageDataStub.asObservable()
        }
    }

    class FakeBiometryManager: BiometryManager {
        var deviceAuthAvailableStub: Bool!

        override var deviceAuthenticationAvailable: Bool {
            return self.deviceAuthAvailableStub
        }
    }

    private var view: FakeSettingsView!
    private var dispatcher: FakeDispatcher!
    private var userDefaultStore: FakeUserDefaultStore!
    private var biometryManager: FakeBiometryManager!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()

    var subject: SettingListPresenter!

    override func spec() {
        describe("SettingListPresenter") {
            beforeEach {
                self.view = FakeSettingsView()
                self.view.itemsObserver = self.scheduler.createObserver([SettingSectionModel].self)

                self.dispatcher = FakeDispatcher()
                self.userDefaultStore = FakeUserDefaultStore()
                self.biometryManager = FakeBiometryManager()

                self.subject = SettingListPresenter(view: self.view,
                                                    dispatcher: self.dispatcher,
                                                    userDefaultStore: self.userDefaultStore,
                                                    biometryManager: self.biometryManager)
            }

            describe("onViewReady") {
                describe("when device auth is available") {
                    beforeEach {
                        self.biometryManager.deviceAuthAvailableStub = true
                    }

                    describe("onSignOut") {
                        beforeEach {
                            self.subject.onViewReady()
                            self.view.fakeButtonPress.onNext(())
                        }

                        it("locks the application and routes to the login flow") {
                            let loginRouteAction = self.dispatcher.dispatchedActions.popLast() as! LoginRouteAction
                            expect(loginRouteAction).to(equal(.welcome))

                            let dataStoreAction = self.dispatcher.dispatchedActions.popLast() as! DataStoreAction
                            expect(dataStoreAction).to(equal(.lock))
                        }
                    }

                    describe("detail values on view modules") {
                        beforeEach {
                            self.subject.onViewReady()
                            self.userDefaultStore.autoLockStub.onNext(Setting.AutoLock.OneHour)
                            self.userDefaultStore.preferredBrowserStub.onNext(Setting.PreferredBrowser.Focus)
                            self.userDefaultStore.recordUsageDataStub.onNext(true)
                        }

                        it("sets detail value for autolock") {
                            let autoLockCellConfig = self.view.itemsObserver.events.last!.value.element![1].items[1]
                            expect(autoLockCellConfig.detailText).to(equal(Constant.string.autoLockOneHour))
                        }

                        it("sets detail value for preferred browser") {
                            let preferredBrowserCellConfig = self.view.itemsObserver.events.last!.value.element![1].items[2]
                            expect(preferredBrowserCellConfig.detailText).to(equal(Setting.PreferredBrowser.Focus.toString()))
                        }
                    }
                }

                describe("when device auth is not available") {
                    beforeEach {
                        self.biometryManager.deviceAuthAvailableStub = false
                    }

                    describe("onSignOut") {
                        beforeEach {
                            self.subject.onViewReady()
                            self.view.fakeButtonPress.onNext(())
                        }

                        it("presents alert onSignOut") {
                            expect(self.view.displayAlertControllerCalled).to(beTrue())
                        }

                        describe("on button tap") {
                            beforeEach {
                                self.view.displayAlertControllerButtons?.last?.tapObserver?.onNext(())
                            }

                            it("routes to set passcode") {
                                expect(self.dispatcher.dispatchedActions.popLast() as? SettingLinkAction).to(equal(.touchIDPasscode))
                            }
                        }
                    }

                    describe("detail values on view modules") {
                        beforeEach {
                            self.subject.onViewReady()
                            self.userDefaultStore.autoLockStub.onNext(Setting.AutoLock.OneHour)
                            self.userDefaultStore.preferredBrowserStub.onNext(Setting.PreferredBrowser.Focus)
                            self.userDefaultStore.recordUsageDataStub.onNext(true)
                        }

                        it("does not show autolock") {
                            expect(self.view.itemsObserver.events.last!.value.element![1].items.count).to(equal(2))
                        }

                        it("sets detail value for preferred browser") {
                            let preferredBrowserCellConfig = self.view.itemsObserver.events.last!.value.element![1].items[1]
                            expect(preferredBrowserCellConfig.detailText).to(equal(Setting.PreferredBrowser.Focus.toString()))
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
                    expect(self.dispatcher.dispatchedActions.last as? SettingAction).to(equal(SettingAction.recordUsageData(enabled: false)))
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
                    let argument = self.dispatcher.dispatchedActions.popLast() as! MainRouteAction
                    expect(argument).to(equal(.list))
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
                        let argument = self.dispatcher.dispatchedActions.popLast() as! SettingRouteAction
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
                        expect(self.dispatcher.dispatchedActions).to(beEmpty())
                    }
                }
            }
        }
    }
}

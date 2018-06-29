/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest
import UIKit

@testable import Lockbox

class RootPresenterSpec: QuickSpec {
    class FakeRootView: RootViewProtocol {
        var topViewIsArgument: UIViewController.Type?
        var topViewIsVar: Bool!

        var modalViewIsArgument: UIViewController.Type?
        var modalViewIsVar: Bool!

        var mainStackIsArgument: UINavigationController.Type?
        var mainStackIsVar: Bool!

        var modalStackIsArgument: UINavigationController.Type?
        var modalStackIsVar: Bool!

        var startMainStackArgument: UINavigationController.Type?
        var startModalStackArgument: UINavigationController?
        var dismissModalCalled: Bool = false

        var pushLoginViewRouteArgument: LoginRouteAction?
        var pushMainViewArgument: MainRouteAction?
        var pushSettingViewArgument: SettingRouteAction?

        func topViewIs<T: UIViewController>(_ type: T.Type) -> Bool {
            self.topViewIsArgument = type
            return self.topViewIsVar
        }

        func modalViewIs<T: UIViewController>(_ type: T.Type) -> Bool {
            self.modalViewIsArgument = type
            return self.modalViewIsVar
        }

        func mainStackIs<T: UINavigationController>(_ type: T.Type) -> Bool {
            self.mainStackIsArgument = type
            return self.mainStackIsVar
        }

        func modalStackIs<T: UINavigationController>(_ type: T.Type) -> Bool {
            self.modalStackIsArgument = type
            return self.modalStackIsVar
        }

        func startMainStack<T: UINavigationController>(_ type: T.Type) {
            self.startMainStackArgument = type
        }

        func startModalStack<T: UINavigationController>(_ navigationController: T) {
            self.startModalStackArgument = navigationController
        }

        func dismissModals() {
            self.dismissModalCalled = true
        }

        func pushLoginView(view: LoginRouteAction) {
            self.pushLoginViewRouteArgument = view
        }

        func pushMainView(view: MainRouteAction) {
            self.pushMainViewArgument = view
        }

        func pushSettingView(view: SettingRouteAction) {
            self.pushSettingViewArgument = view
        }
    }

    class FakeRouteStore: RouteStore {
        let onRouteSubject = PublishSubject<RouteAction>()

        override var onRoute: Observable<RouteAction> {
            return onRouteSubject.asObservable()
        }
    }

    class FakeDataStore: DataStore {
        let lockedSubject = PublishSubject<Bool>()
        let syncSubject = PublishSubject<SyncState>()
        let storageStateSubject = PublishSubject<LoginStoreState>()

        override var locked: Observable<Bool> {
            return self.lockedSubject.asObservable()
        }

        override var syncState: Observable<SyncState> {
            return self.syncSubject.asObservable()
        }

        override var storageState: Observable<LoginStoreState> {
            return self.storageStateSubject.asObservable()
        }
    }

    class FakeTelemetryStore: TelemetryStore {
        let telemetryStub = PublishSubject<TelemetryAction>()

        override var telemetryFilter: Observable<TelemetryAction> {
            return telemetryStub.asObservable()
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeArgument = action
        }
    }

    class FakeTelemetryActionHandler: TelemetryActionHandler {
        var telemetryListener: TestableObserver<TelemetryAction>!

        override var telemetryActionListener: AnyObserver<TelemetryAction> {
            get {
                return self.telemetryListener.asObserver()
            }

            set {
            }
        }
    }

    class FakeDataStoreActionHandler: DataStoreActionHandler {
        var action: DataStoreAction?

        override func invoke(_ action: DataStoreAction) {
            self.action = action
        }
    }

    class FakeBiometryManager: BiometryManager {
        var deviceAuthAvailableStub: Bool!

        override var deviceAuthenticationAvailable: Bool {
            return self.deviceAuthAvailableStub
        }
    }

    private var view: FakeRootView!
    private var routeStore: FakeRouteStore!
    private var dataStore: FakeDataStore!
    private var telemetryStore: FakeTelemetryStore!
    private var routeActionHandler: FakeRouteActionHandler!
    private var telemetryActionHandler: FakeTelemetryActionHandler!
    private var dataStoreActionHandler: FakeDataStoreActionHandler!
    private var biometryManager: FakeBiometryManager!
    private let scheduler = TestScheduler(initialClock: 0)
    var subject: RootPresenter!

    override func spec() {
        describe("RootPresenter") {
            beforeEach {
                self.view = FakeRootView()
                self.routeStore = FakeRouteStore()
                self.dataStore = FakeDataStore()
                self.telemetryStore = FakeTelemetryStore()
                self.routeActionHandler = FakeRouteActionHandler()
                self.telemetryActionHandler = FakeTelemetryActionHandler()
                self.dataStoreActionHandler = FakeDataStoreActionHandler()
                self.biometryManager = FakeBiometryManager()
                self.telemetryActionHandler.telemetryListener = self.scheduler.createObserver(TelemetryAction.self)
                self.biometryManager.deviceAuthAvailableStub = true

                self.subject = RootPresenter(
                        view: self.view,
                        routeStore: self.routeStore,
                        dataStore: self.dataStore,
                        telemetryStore: self.telemetryStore,
                        routeActionHandler: self.routeActionHandler,
                        telemetryActionHandler: self.telemetryActionHandler,
                        biometryManager: self.biometryManager
                )
            }

            describe("when the user is missing the itemlistsort setting") {
                beforeEach {
                    UserDefaults.standard.removeObject(forKey: SettingKey.itemListSort.rawValue)

                    self.subject = RootPresenter(
                            view: self.view,
                            routeStore: self.routeStore,
                            dataStore: self.dataStore,
                            telemetryStore: self.telemetryStore,
                            routeActionHandler: self.routeActionHandler,
                            telemetryActionHandler: self.telemetryActionHandler,
                            biometryManager: self.biometryManager
                    )
                }

                it("sets the key") {
                    expect(UserDefaults.standard.object(forKey: SettingKey.itemListSort.rawValue) as! String).to(equal(Constant.setting.defaultItemListSort.rawValue))
                }
            }

            describe("when the datastore state changes, regardless of synced state") {
                it("routes to the welcome view") {
                    self.dataStore.storageStateSubject.onNext(.Unprepared)
                    let arg = self.routeActionHandler.invokeArgument as! LoginRouteAction
                    expect(arg).to(equal(LoginRouteAction.welcome))
                }

                it("routes to the list view") {
                    self.dataStore.storageStateSubject.onNext(.Preparing)
                    let arg = self.routeActionHandler.invokeArgument as! MainRouteAction
                    expect(arg).to(equal(MainRouteAction.list))
                }

                it("routes to the welcome view") {
                    self.dataStore.storageStateSubject.onNext(.Locked)
                    let arg = self.routeActionHandler.invokeArgument as! LoginRouteAction
                    expect(arg).to(equal(LoginRouteAction.welcome))
                }

                it("routes to the list view") {
                    self.dataStore.storageStateSubject.onNext(.Unlocked)
                    let arg = self.routeActionHandler.invokeArgument as! MainRouteAction
                    expect(arg).to(equal(MainRouteAction.list))
                }
            }

            describe("when the datastore is locked, regardless of synced state") {
                beforeEach {
                    self.dataStore.storageStateSubject.onNext(.Locked)
                    let arg = self.routeActionHandler.invokeArgument as! LoginRouteAction
                    expect(arg).to(equal(LoginRouteAction.welcome))
                }

                it("routes to the welcome view") {
                    self.dataStore.syncSubject.onNext(.NotSyncable)
                    let arg = self.routeActionHandler.invokeArgument as! LoginRouteAction
                    expect(arg).to(equal(LoginRouteAction.welcome))
                }

                it("routes to the welcome view") {
                    self.dataStore.syncSubject.onNext(.ReadyToSync)
                    let arg = self.routeActionHandler.invokeArgument as! LoginRouteAction
                    expect(arg).to(equal(LoginRouteAction.welcome))
                }

                it("routes to the welcome view") {
                    self.dataStore.syncSubject.onNext(.Synced)
                    let arg = self.routeActionHandler.invokeArgument as! LoginRouteAction
                    expect(arg).to(equal(LoginRouteAction.welcome))
                }

                it("routes to the welcome view") {
                    self.dataStore.syncSubject.onNext(.Syncing)
                    let arg = self.routeActionHandler.invokeArgument as! LoginRouteAction
                    expect(arg).to(equal(LoginRouteAction.welcome))
                }
            }

            describe("when the datastore is unlocked") {
                beforeEach {
                    self.dataStore.lockedSubject.onNext(false)
                }

                describe("when the datastore is not syncable and unprepared") {
                    beforeEach {
                        self.dataStore.storageStateSubject.onNext(.Unprepared)
                        self.dataStore.syncSubject.onNext(.NotSyncable)
                    }

                    it("displays the welcome screen") {
                        let arg = self.routeActionHandler.invokeArgument as! LoginRouteAction
                        expect(arg).to(equal(LoginRouteAction.welcome))
                    }
                }

                describe("any other storage state + sync state value") {
                    it("routes to the list") {
                        self.dataStore.storageStateSubject.onNext(.Unlocked)
                        self.dataStore.syncSubject.onNext(.ReadyToSync)
                        let arg = self.routeActionHandler.invokeArgument as! MainRouteAction
                        expect(arg).to(equal(MainRouteAction.list))
                    }

                    it("routes to the list") {
                        self.dataStore.storageStateSubject.onNext(.Unlocked)
                        self.dataStore.syncSubject.onNext(.Syncing)
                        let arg = self.routeActionHandler.invokeArgument as! MainRouteAction
                        expect(arg).to(equal(MainRouteAction.list))
                    }

                    it("routes to the list") {
                        self.dataStore.storageStateSubject.onNext(.Unlocked)
                        self.dataStore.syncSubject.onNext(.Synced)
                        let arg = self.routeActionHandler.invokeArgument as! MainRouteAction
                        expect(arg).to(equal(MainRouteAction.list))
                    }

                    it("routes to the list") {
                        self.dataStore.storageStateSubject.onNext(.Unlocked)
                        self.dataStore.syncSubject.onNext(.NotSyncable)
                        let arg = self.routeActionHandler.invokeArgument as! MainRouteAction
                        expect(arg).to(equal(MainRouteAction.list))
                    }
                }
            }

            describe("onViewReady") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("LoginRouteActions") {
                    describe("if the login stack is already displayed") {
                        beforeEach {
                            self.view.mainStackIsVar = true
                        }

                        describe(".login") {
                            describe("if the top view is not already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.welcome)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("checks & does not start the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the WelcomeView & tells the view to show the loginview") {
                                    expect(self.view.topViewIsArgument === WelcomeView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(equal(LoginRouteAction.welcome))
                                }
                            }

                            describe("if the top view is already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.welcome)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("checks & does not start the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the WelcomeView & nothing happens") {
                                    expect(self.view.topViewIsArgument === WelcomeView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(beNil())
                                }
                            }
                        }

                        describe(".fxa") {
                            describe("if the top view is not already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.welcome)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the FxAView & tells the view to show the loginview") {
                                    expect(self.view.topViewIsArgument === WelcomeView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(equal(LoginRouteAction.welcome))
                                }
                            }

                            describe("if the top view is already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.welcome)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the FxAView & nothing happens") {
                                    expect(self.view.topViewIsArgument === WelcomeView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(beNil())
                                }
                            }
                        }

                        describe(".onboardingConfirmation") {
                            describe("if the top view is not already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.onboardingConfirmation)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the onboardingconfirmationview & tells the view to show the onboardingconfirmation") {
                                    expect(self.view.topViewIsArgument === OnboardingConfirmationView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(equal(LoginRouteAction.onboardingConfirmation))
                                }
                            }

                            describe("if the top view is already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.onboardingConfirmation)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the FxAView & nothing happens") {
                                    expect(self.view.topViewIsArgument === OnboardingConfirmationView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(beNil())
                                }
                            }
                        }
                    }

                    describe("if the login stack is not already displayed") {
                        beforeEach {
                            self.view.mainStackIsVar = false
                        }

                        describe(".login") {
                            describe("if the top view is not already the fxa view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.fxa)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the fxa stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === LoginNavigationController.self).to(beTrue())
                                }

                                it("checks for the WelcomeView & tells the view to show the fxaview") {
                                    expect(self.view.topViewIsArgument === FxAView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(equal(LoginRouteAction.fxa))
                                }
                            }

                            describe("if the top view is already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.welcome)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === LoginNavigationController.self).to(beTrue())
                                }

                                it("checks for the WelcomeView & nothing happens") {
                                    expect(self.view.topViewIsArgument === WelcomeView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(beNil())
                                }
                            }
                        }

                        describe(".fxa") {
                            describe("if the top view is not already the fxa view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.fxa)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === LoginNavigationController.self).to(beTrue())
                                }

                                it("checks for the FxAView & tells the view to show the loginview") {
                                    expect(self.view.topViewIsArgument === FxAView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(equal(LoginRouteAction.fxa))
                                }
                            }

                            describe("if the top view is already the fxa view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.fxa)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === LoginNavigationController.self).to(beTrue())
                                }

                                it("checks for the FxAView & nothing happens") {
                                    expect(self.view.topViewIsArgument === FxAView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(beNil())
                                }
                            }
                        }

                        describe(".onboardingConfirmation") {
                            describe("if the top view is not already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.onboardingConfirmation)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === LoginNavigationController.self).to(beTrue())
                                }

                                it("checks for the onboardingconfirmationview & tells the view to show the it") {
                                    expect(self.view.topViewIsArgument === OnboardingConfirmationView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(equal(LoginRouteAction.onboardingConfirmation))
                                }
                            }

                            describe("if the top view is already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.onboardingConfirmation)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === LoginNavigationController.self).to(beTrue())
                                }

                                it("checks for the onboardingconfimrationview & nothing happens") {
                                    expect(self.view.topViewIsArgument === OnboardingConfirmationView.self).to(beTrue())
                                    expect(self.view.pushLoginViewRouteArgument).to(beNil())
                                }
                            }
                        }
                    }
                }

                describe("MainRouteActions") {
                    describe("if the main stack is already displayed") {
                        beforeEach {
                            self.view.mainStackIsVar = true
                        }

                        describe(".list") {
                            describe("if the top view is not already the list view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(MainRouteAction.list)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the login stack") {
                                    expect(self.view.mainStackIsArgument === MainNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the ListView & tells the view to show the loginview") {
                                    expect(self.view.topViewIsArgument === ItemListView.self).to(beTrue())
                                    expect(self.view.pushMainViewArgument).to(equal(MainRouteAction.list))
                                }
                            }

                            describe("if the top view is already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(MainRouteAction.list)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the main stack") {
                                    expect(self.view.mainStackIsArgument === MainNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the ListView & nothing happens") {
                                    expect(self.view.topViewIsArgument === ItemListView.self).to(beTrue())
                                    expect(self.view.pushMainViewArgument).to(beNil())
                                }
                            }
                        }

                        describe(".detail") {
                            let itemId = "sdfjhqwnmsdlksdf"
                            describe("if the top view is not already the detail view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(MainRouteAction.detail(itemId: itemId))
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the main stack") {
                                    expect(self.view.mainStackIsArgument === MainNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the DetailView & tells the view to show the detail view") {
                                    expect(self.view.topViewIsArgument === ItemDetailView.self).to(beTrue())
                                    expect(self.view.pushMainViewArgument)
                                            .to(equal(MainRouteAction.detail(itemId: itemId)))
                                }
                            }

                            describe("if the top view is already the detail view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(MainRouteAction.detail(itemId: itemId))
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the main stack") {
                                    expect(self.view.mainStackIsArgument === MainNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the DetailView & nothing happens") {
                                    expect(self.view.topViewIsArgument === ItemDetailView.self).to(beTrue())
                                    expect(self.view.pushMainViewArgument).to(beNil())
                                }
                            }
                        }
                    }

                    describe("if the main stack is not already displayed") {
                        beforeEach {
                            self.view.mainStackIsVar = false
                        }

                        describe(".list") {
                            describe("if the top view is not already the list view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(MainRouteAction.list)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the main stack") {
                                    expect(self.view.mainStackIsArgument === MainNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === MainNavigationController.self).to(beTrue())
                                }

                                it("checks for the ListView & tells the view to show the listview") {
                                    expect(self.view.topViewIsArgument === ItemListView.self).to(beTrue())
                                    expect(self.view.pushMainViewArgument).to(equal(MainRouteAction.list))
                                }
                            }

                            describe("if the top view is already the list view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(MainRouteAction.list)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the main stack") {
                                    expect(self.view.mainStackIsArgument === MainNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === MainNavigationController.self).to(beTrue())
                                }

                                it("checks for the ListView & nothing happens") {
                                    expect(self.view.topViewIsArgument === ItemListView.self).to(beTrue())
                                    expect(self.view.pushMainViewArgument).to(beNil())
                                }
                            }
                        }

                        describe(".detail") {
                            let itemId = "sdfjhqwnmsdlksdf"
                            describe("if the top view is not already the detail view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(MainRouteAction.detail(itemId: itemId))
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the main stack") {
                                    expect(self.view.mainStackIsArgument === MainNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === MainNavigationController.self).to(beTrue())
                                }

                                it("checks for the DetailView & tells the view to show the loginview") {
                                    expect(self.view.topViewIsArgument === ItemDetailView.self).to(beTrue())
                                    expect(self.view.pushMainViewArgument)
                                            .to(equal(MainRouteAction.detail(itemId: itemId)))
                                }
                            }

                            describe("if the top view is already the detail view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(MainRouteAction.detail(itemId: itemId))
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the main stack") {
                                    expect(self.view.mainStackIsArgument === MainNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === MainNavigationController.self).to(beTrue())
                                }

                                it("checks for the DetailView & nothing happens") {
                                    expect(self.view.topViewIsArgument === ItemDetailView.self).to(beTrue())
                                    expect(self.view.pushMainViewArgument).to(beNil())
                                }
                            }
                        }
                    }
                }

                describe("SettingRouteActions") {
                    describe("if the setting stack is already displayed") {
                        beforeEach {
                            self.view.mainStackIsVar = true
                        }

                        describe(".list") {
                            describe("when the top view is the list view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.list)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.topViewIsArgument === SettingListView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(beNil())
                                }
                            }

                            describe("when the top view is not the list view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.list)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.topViewIsArgument === SettingListView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.list))
                                }
                            }
                        }

                        describe(".account") {
                            describe("when the top view is the account view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.account)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.topViewIsArgument === AccountSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(beNil())
                                }
                            }

                            describe("when the top view is not the account view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.account)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.account))
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.topViewIsArgument === AccountSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.account))
                                }
                            }
                        }

                        describe(".preferredBrowser") {
                            describe("when the top view is the preferred browser view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.preferredBrowser)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.topViewIsArgument === PreferredBrowserSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(beNil())
                                }
                            }

                            describe("when the top view is not the preferred browser view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.preferredBrowser)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.preferredBrowser))
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.topViewIsArgument === PreferredBrowserSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.preferredBrowser))
                                }
                            }
                        }
                    }

                    describe("if the setting stack is not already displayed") {
                        beforeEach {
                            self.view.mainStackIsVar = false
                        }

                        describe(".list") {
                            describe("when the top view is the list view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.list)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === SettingNavigationController.self).to(beTrue())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.topViewIsArgument === SettingListView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(beNil())
                                }
                            }

                            describe("when the top view is not the list view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.list)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === SettingNavigationController.self).to(beTrue())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.topViewIsArgument === SettingListView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.list))
                                }
                            }
                        }

                        describe(".account") {
                            describe("when the top view is the account view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.account)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === SettingNavigationController.self).to(beTrue())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.topViewIsArgument === AccountSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(beNil())
                                }
                            }

                            describe("when the top view is not the account view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.account)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === SettingNavigationController.self).to(beTrue())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.topViewIsArgument === AccountSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.account))
                                }
                            }
                        }

                        describe(".preferredBrowser") {
                            describe("when the top view is the preferred browser view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.preferredBrowser)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === SettingNavigationController.self).to(beTrue())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.topViewIsArgument === PreferredBrowserSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(beNil())
                                }
                            }

                            describe("when the top view is not the preferred browser view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.preferredBrowser)
                                }

                                it("dismisses modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the setting stack") {
                                    expect(self.view.mainStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument === SettingNavigationController.self).to(beTrue())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.topViewIsArgument === PreferredBrowserSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.preferredBrowser))
                                }
                            }
                        }
                    }
                }

                describe("ExternalWebsiteRouteActions") {

                }

                describe("telemetry") {
                    let action = CopyAction(text: "somethin", field: .password, itemID: "fsdsdfsf") as TelemetryAction

                    describe("when usage data can be recorded") {
                        beforeEach {
                            UserDefaults.standard.set(true, forKey: SettingKey.recordUsageData.rawValue)
                            self.telemetryStore.telemetryStub.onNext(action)
                        }

                        it("passes all telemetry actions through to the telemetryactionhandler") {
                            expect(self.telemetryActionHandler.telemetryListener.events.last!.value.element!.eventMethod).to(equal(action.eventMethod))
                            expect(self.telemetryActionHandler.telemetryListener.events.last!.value.element!.eventObject).to(equal(action.eventObject))
                        }
                    }

                    describe("when usage data cannot be recorded") {
                        beforeEach {
                            UserDefaults.standard.set(false, forKey: SettingKey.recordUsageData.rawValue)
                            self.telemetryStore.telemetryStub.onNext(action)
                        }

                        it("passes no telemetry actions through to the telemetryactionhandler") {
                            expect(self.telemetryActionHandler.telemetryListener.events.count).to(equal(0))
                        }
                    }
                }
            }
        }
    }

    private func getPresenter() -> RootPresenter {
        return RootPresenter(
                view: self.view,
                routeStore: self.routeStore,
                dataStore: self.dataStore,
                telemetryStore: self.telemetryStore,
                routeActionHandler: self.routeActionHandler,
                dataStoreActionHandler: self.dataStoreActionHandler,
                telemetryActionHandler: self.telemetryActionHandler,
                biometryManager: self.biometryManager
        )
    }
}

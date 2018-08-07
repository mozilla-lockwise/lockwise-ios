/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest
import UIKit
import FxAClient

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

        var modalStackPresented = true

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

    class FakeDispatcher: Dispatcher {
        var dispatchActionArgument: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchActionArgument.append(action)
        }
    }

    class FakeRouteStore: RouteStore {
        let onRouteSubject = PublishSubject<RouteAction>()
        let onboardingSubject = PublishSubject<Bool>()

        override var onRoute: Observable<RouteAction> {
            return onRouteSubject.asObservable()
        }

        override var onboarding: Observable<Bool> {
            return self.onboardingSubject.asObservable()
        }
    }

    class FakeDataStore: DataStore {
        let lockedSubject = PublishSubject<Bool>()
        let syncSubject = PublishSubject<SyncState>()
        let storageStateStub = PublishSubject<LoginStoreState>()

        override var locked: Observable<Bool> {
            return self.lockedSubject.asObservable()
        }

        override var syncState: Observable<SyncState> {
            return self.syncSubject.asObservable()
        }

        override var storageState: Observable<LoginStoreState> {
            return self.storageStateStub.asObservable()
        }
    }

    class FakeTelemetryStore: TelemetryStore {
        let telemetryStub = PublishSubject<TelemetryAction>()

        override var telemetryFilter: Observable<TelemetryAction> {
            return telemetryStub.asObservable()
        }
    }

    class FakeAccountStore: AccountStore {
        let oauthInfoStub = PublishSubject<OAuthInfo?>()
        let profileInfoStub = PublishSubject<Profile?>()

        override var oauthInfo: Observable<OAuthInfo?> {
            return self.oauthInfoStub.asObservable()
        }

        override var profile: Observable<Profile?> {
            return self.profileInfoStub.asObservable()
        }
    }

    class FakeUserDefaultStore: UserDefaultStore {
        var recordUsageStub = PublishSubject<Bool>()

        override var recordUsageData: Observable<Bool> {
            return self.recordUsageStub
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

    class FakeBiometryManager: BiometryManager {
        var deviceAuthAvailableStub: Bool!

        override var deviceAuthenticationAvailable: Bool {
            return self.deviceAuthAvailableStub
        }
    }

    private var view: FakeRootView!
    private var dispatcher: FakeDispatcher!
    private var routeStore: FakeRouteStore!
    private var dataStore: FakeDataStore!
    private var telemetryStore: FakeTelemetryStore!
    private var accountStore: FakeAccountStore!
    private var userDefaultStore: FakeUserDefaultStore!
    private var telemetryActionHandler: FakeTelemetryActionHandler!
    private var biometryManager: FakeBiometryManager!
    private let scheduler = TestScheduler(initialClock: 0)
    var subject: RootPresenter!

    override func spec() {
        describe("RootPresenter") {
            beforeEach {
                self.view = FakeRootView()
                self.dispatcher = FakeDispatcher()
                self.routeStore = FakeRouteStore()
                self.dataStore = FakeDataStore()
                self.telemetryStore = FakeTelemetryStore()
                self.accountStore = FakeAccountStore()
                self.userDefaultStore = FakeUserDefaultStore()
                self.telemetryActionHandler = FakeTelemetryActionHandler()
                self.biometryManager = FakeBiometryManager()
                self.telemetryActionHandler.telemetryListener = self.scheduler.createObserver(TelemetryAction.self)
                self.biometryManager.deviceAuthAvailableStub = true

                self.subject = RootPresenter(
                        view: self.view,
                        dispatcher: self.dispatcher,
                        routeStore: self.routeStore,
                        dataStore: self.dataStore,
                        telemetryStore: self.telemetryStore,
                        accountStore: self.accountStore,
                        userDefaultStore: self.userDefaultStore,
                        telemetryActionHandler: self.telemetryActionHandler,
                        biometryManager: self.biometryManager
                )
            }

            describe("when the oauth info is not available") {
                beforeEach {
                    self.accountStore.oauthInfoStub.onNext(nil)
                    self.accountStore.profileInfoStub.onNext(nil)
                }

                it("routes to the welcome view and resets the datastore") {
                    let dataStoreAction = self.dispatcher.dispatchActionArgument.popLast() as! DataStoreAction
                    expect(dataStoreAction).to(equal(DataStoreAction.reset))
                    let arg = self.dispatcher.dispatchActionArgument.popLast() as! LoginRouteAction
                    expect(arg).to(equal(LoginRouteAction.welcome))
                }
            }

            xdescribe("when the oauth info and profile info are present") {
                beforeEach {
                    // todo: update this spec with constructable OAuthInfo and Profile
                    self.dataStore.lockedSubject.onNext(false)
                }

                it("updates the datastore credentials") {
                    let arg = self.dispatcher.dispatchActionArgument.popLast() as! MainRouteAction
                    expect(arg).to(equal(MainRouteAction.list))
                }
            }

            describe("when the datastore is locked") {
                beforeEach {
                    self.dataStore.storageStateStub.onNext(LoginStoreState.Locked)
                }

                it("routes to the welcome screen") {
                    let arg = self.dispatcher.dispatchActionArgument.popLast() as! LoginRouteAction
                    expect(arg).to(equal(LoginRouteAction.welcome))
                }
            }

            describe("when the datastore is unlocked") {
                beforeEach {
                    self.dataStore.storageStateStub.onNext(LoginStoreState.Unlocked)
                }

                it("routes to the list") {
                    let arg = self.dispatcher.dispatchActionArgument.popLast() as! MainRouteAction
                    expect(arg).to(equal(MainRouteAction.list))
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
                    describe("if onboarding is in process") {
                        beforeEach {
                            self.routeStore.onboardingSubject.onNext(true)
                            self.routeStore.onRouteSubject.onNext(MainRouteAction.list)
                        }

                        it("does nothing") {
                            expect(self.view.mainStackIsArgument).to(beNil())
                            expect(self.view.topViewIsArgument).to(beNil())
                            expect(self.view.pushMainViewArgument).to(beNil())
                        }
                    }

                    describe("if the main stack is already displayed") {
                        beforeEach {
                            self.routeStore.onboardingSubject.onNext(false)
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
                            self.routeStore.onboardingSubject.onNext(false)
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
                    describe("if onboarding is in process") {
                        beforeEach {
                            self.routeStore.onboardingSubject.onNext(true)
                            self.routeStore.onRouteSubject.onNext(SettingRouteAction.list)
                        }

                        it("does nothing") {
                            expect(self.view.mainStackIsArgument).to(beNil())
                            expect(self.view.topViewIsArgument).to(beNil())
                            expect(self.view.pushSettingViewArgument).to(beNil())
                        }
                    }

                    describe("if the setting stack is already displayed") {
                        beforeEach {
                            self.routeStore.onboardingSubject.onNext(false)
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
                            self.routeStore.onboardingSubject.onNext(false)
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
                            self.userDefaultStore.recordUsageStub.onNext(true)
                            self.telemetryStore.telemetryStub.onNext(action)
                        }

                        it("passes all telemetry actions through to the telemetryactionhandler") {
                            expect(self.telemetryActionHandler.telemetryListener.events.last!.value.element!.eventMethod).to(equal(action.eventMethod))
                            expect(self.telemetryActionHandler.telemetryListener.events.last!.value.element!.eventObject).to(equal(action.eventObject))
                        }
                    }

                    describe("when usage data cannot be recorded") {
                        beforeEach {
                            self.userDefaultStore.recordUsageStub.onNext(false)
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
                dispatcher: self.dispatcher,
                routeStore: self.routeStore,
                dataStore: self.dataStore,
                telemetryStore: self.telemetryStore,
                telemetryActionHandler: self.telemetryActionHandler,
                biometryManager: self.biometryManager
        )
    }
}

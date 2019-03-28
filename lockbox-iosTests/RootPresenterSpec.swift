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
import SwiftKeychainWrapper

@testable import Lockbox

class RootPresenterSpec: QuickSpec {
    class FakeRootView: RootViewProtocol {
        var topViewIsArgument: UIViewController.Type?
        var topViewIsVar: Bool!

        var modalViewIsArgument: UIViewController.Type?
        var modalViewIsVar: Bool!

        var mainStackIsArgument: UIViewController.Type?
        var mainStackIsVar: Bool!

        var modalStackIsArgument: UIViewController.Type?
        var modalStackIsVar: Bool!

        var startMainStackArgument: UIViewController?
        var startModalStackArgument: UIViewController?
        var dismissModalCalled: Bool = false

        var sidebarViewIsArgument: UIViewController.Type?
        var sidebarViewIsVar: Bool!

        var pushArgument: UIViewController?
        var pushDetailArgument: UIViewController?
        var pushSidebarArgument: UIViewController?

        var detailViewIsArgument: UIViewController.Type!
        var detailViewIsVar: Bool!

        var popViewCalled = false
        var popToRootCalled = false

        func detailViewIs<T>(_ type: T.Type) -> Bool where T: UIViewController {
            self.detailViewIsArgument = type
            return self.detailViewIsVar
        }

        func topViewIs<T: UIViewController>(_ type: T.Type) -> Bool {
            self.topViewIsArgument = type
            return self.topViewIsVar
        }

        func modalViewIs<T: UIViewController>(_ type: T.Type) -> Bool {
            self.modalViewIsArgument = type
            return self.modalViewIsVar
        }

        func sidebarViewIs<T>(_ type: T.Type) -> Bool where T: UIViewController {
            self.sidebarViewIsArgument = type
            return self.sidebarViewIsVar
        }

        func mainStackIs<T: UIViewController>(_ type: T.Type) -> Bool {
            self.mainStackIsArgument = type
            return self.mainStackIsVar
        }

        func modalStackIs<T: UIViewController>(_ type: T.Type) -> Bool {
            self.modalStackIsArgument = type
            return self.modalStackIsVar
        }

        var modalStackPresented = true

        func startMainStack<T>(_ viewController: T) where T: UIViewController {
            self.startMainStackArgument = viewController
        }

        func startModalStack<T: UIViewController>(_ viewController: T) {
            self.startModalStackArgument = viewController
        }

        func dismissModals() {
            self.dismissModalCalled = true
        }

        func push(view: UIViewController) {
            self.pushArgument = view
        }

        func pushSidebar(view: UIViewController) {
            self.pushSidebarArgument = view
        }

        func pushDetail(view: UIViewController) {
            self.pushDetailArgument = view
        }

        func popView() {
            self.popViewCalled = true
        }

        func popToRoot() {
            self.popToRootCalled = true
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
        let syncCredStub = PublishSubject<SyncCredential?>()
        let profileInfoStub = PublishSubject<FxAClient.Profile?>()

        override func initialized() {
            //noop
        }

        override var syncCredentials: Observable<SyncCredential?> {
            return self.syncCredStub.asObservable()
        }

        override var profile: Observable<FxAClient.Profile?> {
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

    class FakeSentryManager: Lockbox.Sentry {
        var setupCalled: Bool = false

        override func setup(sendUsageData: Bool) {
            if sendUsageData {
             self.setupCalled = true
            }
        }
    }

    class FakeAdjustManager: AdjustManager {
        var enabledValue: Bool?

        override func setEnabled(_ enabled: Bool) {
            self.enabledValue = enabled
        }
    }

    class FakeSizeClassStore: SizeClassStore {
        var showSidebarStub = PublishSubject<Bool>()

        override var shouldDisplaySidebar: Observable<Bool> {
            return self.showSidebarStub.asObservable()
        }
    }

    class FakeLifecycleStore: LifecycleStore {
        var filterStub = PublishSubject<LifecycleAction>()

        override var lifecycleFilter: Observable<LifecycleAction> {
            return self.filterStub.asObservable()
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
    private var sentryManager: FakeSentryManager!
    private var adjustManager: FakeAdjustManager!
    private var sizeClassStore: FakeSizeClassStore!
    private var lifecycleStore: FakeLifecycleStore!
    private let scheduler = TestScheduler(initialClock: 0)
    var subject: RootPresenter!

    override func spec() {
        describe("RootPresenter") {
            beforeEach {
                self.view = FakeRootView()
                self.dispatcher = FakeDispatcher()
                self.routeStore = FakeRouteStore()
                self.dataStore = FakeDataStore(dispatcher: self.dispatcher, keychainWrapper: KeychainWrapper.standard, userDefaults: UserDefaults.standard)
                self.telemetryStore = FakeTelemetryStore()
                self.accountStore = FakeAccountStore()
                self.userDefaultStore = FakeUserDefaultStore()
                self.telemetryActionHandler = FakeTelemetryActionHandler(accountStore: self.accountStore)
                self.biometryManager = FakeBiometryManager()
                self.sentryManager = FakeSentryManager()
                self.adjustManager = FakeAdjustManager()
                self.telemetryActionHandler.telemetryListener = self.scheduler.createObserver(TelemetryAction.self)
                self.biometryManager.deviceAuthAvailableStub = true
                self.sizeClassStore = FakeSizeClassStore()
                self.lifecycleStore = FakeLifecycleStore()

                self.subject = RootPresenter(
                        view: self.view,
                        dispatcher: self.dispatcher,
                        routeStore: self.routeStore,
                        dataStore: self.dataStore,
                        telemetryStore: self.telemetryStore,
                        accountStore: self.accountStore,
                        userDefaultStore: self.userDefaultStore,
                        lifecycleStore: self.lifecycleStore,
                        telemetryActionHandler: self.telemetryActionHandler,
                        biometryManager: self.biometryManager,
                        adjustManager: self.adjustManager,
                        sizeClassStore: self.sizeClassStore
                )
            }

            describe("when the oauth info is not available") {
                beforeEach {
                    self.accountStore.syncCredStub.onNext(nil)
                    self.accountStore.profileInfoStub.onNext(nil)
                }

                it("clears the account, credential provider, routes to the welcome view and resets the datastore") {
                    let arg = self.dispatcher.dispatchActionArgument.popLast() as! AccountAction
                    expect(arg).to(equal(AccountAction.clear))

                    let credentialProviderAction = self.dispatcher.dispatchActionArgument.popLast() as! CredentialProviderAction
                    expect(credentialProviderAction).to(equal(CredentialProviderAction.clear))

                    let dataStoreAction = self.dispatcher.dispatchActionArgument.popLast() as! DataStoreAction
                    expect(dataStoreAction).to(equal(DataStoreAction.reset))

                    let loginRouteAction = self.dispatcher.dispatchActionArgument.popLast() as! LoginRouteAction
                    expect(loginRouteAction).to(equal(LoginRouteAction.welcome))
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

                it("routes to the list and refreshes the credential provider store") {
                    let credArg = self.dispatcher.dispatchActionArgument.popLast() as! CredentialProviderAction
                    expect(credArg).to(equal(CredentialProviderAction.refresh))
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
                                    expect(self.view.popToRootCalled).to(beTrue())
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
                                    expect(self.view.pushArgument).to(beNil())
                                    expect(self.view.popToRootCalled).to(beFalse())
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
                                    expect(self.view.popToRootCalled).to(beTrue())
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
                                    expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.pushArgument is OnboardingConfirmationView).to(beTrue())
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
                                    expect(self.view.pushArgument).to(beNil())
                                }
                            }
                        }

                        describe(".autofillOnboarding") {
                            describe("if the top view is not already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.autofillOnboarding)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the autofillOnboarding & tells the view to show the autofillOnboarding") {
                                    expect(self.view.topViewIsArgument === AutofillOnboardingView.self).to(beTrue())
                                    expect(self.view.pushArgument is AutofillOnboardingView).to(beTrue())
                                }
                            }

                            describe("if the top view is already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.autofillOnboarding)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the FxAView & nothing happens") {
                                    expect(self.view.topViewIsArgument === AutofillOnboardingView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.startMainStackArgument is LoginNavigationController).to(beTrue())
                                }

                                it("checks for the WelcomeView & tells the view to show the fxaview") {
                                    expect(self.view.topViewIsArgument === FxAView.self).to(beTrue())
                                    expect(self.view.pushArgument is FxAView).to(beTrue())
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
                                    expect(self.view.startMainStackArgument is LoginNavigationController).to(beTrue())
                                }

                                it("checks for the WelcomeView & nothing happens") {
                                    expect(self.view.topViewIsArgument === WelcomeView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.startMainStackArgument is LoginNavigationController).to(beTrue())
                                }

                                it("checks for the FxAView & tells the view to show the loginview") {
                                    expect(self.view.topViewIsArgument === FxAView.self).to(beTrue())
                                    expect(self.view.pushArgument is FxAView).to(beTrue())
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
                                    expect(self.view.startMainStackArgument is LoginNavigationController).to(beTrue())
                                }

                                it("checks for the FxAView & nothing happens") {
                                    expect(self.view.topViewIsArgument === FxAView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.startMainStackArgument is LoginNavigationController).to(beTrue())
                                }

                                it("checks for the onboardingconfirmationview & tells the view to show the it") {
                                    expect(self.view.topViewIsArgument === OnboardingConfirmationView.self).to(beTrue())
                                    expect(self.view.pushArgument is OnboardingConfirmationView).to(beTrue())
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
                                    expect(self.view.startMainStackArgument is LoginNavigationController).to(beTrue())
                                }

                                it("checks for the onboardingconfimrationview & nothing happens") {
                                    expect(self.view.topViewIsArgument === OnboardingConfirmationView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
                                }
                            }
                        }

                        describe(".autofillOnboarding") {
                            describe("if the top view is not already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.autofillOnboarding)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument is LoginNavigationController).to(beTrue())
                                }

                                it("checks for the autofillOnboadingView & tells the view to show the it") {
                                    expect(self.view.topViewIsArgument === AutofillOnboardingView.self).to(beTrue())
                                    expect(self.view.pushArgument is AutofillOnboardingView).to(beTrue())
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
                                    expect(self.view.startMainStackArgument is LoginNavigationController).to(beTrue())
                                }

                                it("checks for the onboardingconfimrationview & nothing happens") {
                                    expect(self.view.topViewIsArgument === OnboardingConfirmationView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
                                }
                            }
                        }

                        describe(".autofillInstructions") {
                            describe("if the top view is not already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.autofillInstructions)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument is LoginNavigationController).to(beTrue())
                                }

                                it("checks for the autofillOnboadingView & tells the view to show the it") {
                                    expect(self.view.topViewIsArgument === AutofillInstructionsView.self).to(beTrue())
                                    expect(self.view.pushArgument is AutofillInstructionsView).to(beTrue())
                                }
                            }

                            describe("if the top view is already the login view") {
                                beforeEach {
                                    self.view.topViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(LoginRouteAction.autofillInstructions)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the login stack") {
                                    expect(self.view.mainStackIsArgument === LoginNavigationController.self).to(beTrue())
                                    expect(self.view.startMainStackArgument is LoginNavigationController).to(beTrue())
                                }

                                it("checks for the autofillinstructions & nothing happens") {
                                    expect(self.view.topViewIsArgument === AutofillInstructionsView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
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
                            expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.mainStackIsArgument === SplitView.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the ListView & tells the view to show the loginview") {
                                    expect(self.view.topViewIsArgument === ItemListView.self).to(beTrue())
                                    expect(self.view.popToRootCalled).to(beTrue())
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
                                    expect(self.view.mainStackIsArgument === SplitView.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the ListView & nothing happens") {
                                    expect(self.view.topViewIsArgument === ItemListView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
                                }
                            }
                        }

                        describe(".detail") {
                            let itemId = "sdfjhqwnmsdlksdf"
                            describe("if the top view is not already the detail view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                self.routeStore.onRouteSubject.onNext(MainRouteAction.detail(itemId: itemId))
                                    self.sizeClassStore.showSidebarStub.onNext(false)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("does not start the main stack") {
                                    expect(self.view.mainStackIsArgument === SplitView.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the DetailView & tells the view to show the detail view") {
                                    expect(self.view.topViewIsArgument === ItemDetailView.self).to(beTrue())
                                    expect(self.view.pushArgument is ItemDetailView)
                                            .to(beTrue())
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
                                    expect(self.view.mainStackIsArgument === SplitView.self).to(beTrue())
                                    expect(self.view.startMainStackArgument).to(beNil())
                                }

                                it("checks for the DetailView & nothing happens") {
                                    expect(self.view.topViewIsArgument === ItemDetailView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.mainStackIsArgument === SplitView.self).to(beTrue())
                                    expect(self.view.startMainStackArgument is SplitView).to(beTrue())
                                }

                                it("checks for the ListView & tells the view to show the listview") {
                                    expect(self.view.topViewIsArgument === ItemListView.self).to(beTrue())
                                    expect(self.view.popToRootCalled).to(beTrue())
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
                                    expect(self.view.mainStackIsArgument === SplitView.self).to(beTrue())
                                    expect(self.view.startMainStackArgument is SplitView).to(beTrue())
                                }

                                it("checks for the ListView & nothing happens") {
                                    expect(self.view.topViewIsArgument === ItemListView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
                                }
                            }
                        }

                        describe(".detail") {
                            let itemId = "sdfjhqwnmsdlksdf"
                            describe("if the top view is not already the detail view") {
                                beforeEach {
                                    self.view.topViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(MainRouteAction.detail(itemId: itemId))
                                    self.sizeClassStore.showSidebarStub.onNext(false)
                                }

                                it("dismisses any modals") {
                                    expect(self.view.dismissModalCalled).to(beTrue())
                                }

                                it("starts the main stack") {
                                    expect(self.view.mainStackIsArgument === SplitView.self).to(beTrue())
                                    expect(self.view.startMainStackArgument is SplitView).to(beTrue())
                                }

                                it("checks for the DetailView & tells the view to show the loginview") {
                                    expect(self.view.topViewIsArgument === ItemDetailView.self).to(beTrue())
                                    expect(self.view.pushArgument is ItemDetailView).to(beTrue())
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
                                    expect(self.view.mainStackIsArgument === SplitView.self).to(beTrue())
                                    expect(self.view.startMainStackArgument is SplitView).to(beTrue())
                                }

                                it("checks for the DetailView & nothing happens") {
                                    expect(self.view.topViewIsArgument === ItemDetailView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
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
                            expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.popToRootCalled).to(beTrue())
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
                                    expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.popToRootCalled).to(beFalse())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.topViewIsArgument === AccountSettingView.self).to(beTrue())
                                    expect(self.view.pushArgument is AccountSettingView).to(beTrue())
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
                                    expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.pushArgument is PreferredBrowserSettingView).to(beTrue())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.topViewIsArgument === PreferredBrowserSettingView.self).to(beTrue())
                                    expect(self.view.pushArgument is PreferredBrowserSettingView).to(beTrue())
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
                                    expect(self.view.startMainStackArgument is SettingNavigationController).to(beTrue())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.topViewIsArgument === SettingListView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.startMainStackArgument is SettingNavigationController).to(beTrue())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.topViewIsArgument === SettingListView.self).to(beTrue())
                                    expect(self.view.popToRootCalled).to(beTrue())
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
                                    expect(self.view.startMainStackArgument is SettingNavigationController).to(beTrue())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.topViewIsArgument === AccountSettingView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.startMainStackArgument is SettingNavigationController).to(beTrue())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.topViewIsArgument === AccountSettingView.self).to(beTrue())
                                    expect(self.view.pushArgument is AccountSettingView).to(beTrue())
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
                                    expect(self.view.startMainStackArgument is SettingNavigationController).to(beTrue())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.topViewIsArgument === PreferredBrowserSettingView.self).to(beTrue())
                                    expect(self.view.pushArgument).to(beNil())
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
                                    expect(self.view.startMainStackArgument is SettingNavigationController).to(beTrue())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.topViewIsArgument === PreferredBrowserSettingView.self).to(beTrue())
                                    expect(self.view.pushArgument is PreferredBrowserSettingView).to(beTrue())
                                }
                            }
                        }

                        describe(".autofillInstructions") {
                            describe("when top view is not the autofillInstructions") {
                                beforeEach {
                                    self.view.modalStackIsVar = false
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.autofillInstructions)
                                }

                                it("starts the modal") {
                                    expect(self.view.modalStackIsArgument === AutofillInstructionsNavigationController.self).to(beTrue())
                                    expect(self.view.startModalStackArgument).notTo(beNil())
                                }
                            }

                            describe("when top view is the autofillInstructions") {
                                beforeEach {
                                    self.view.modalStackIsVar = true
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.autofillInstructions)
                                }

                                it("does not start the modal") {
                                    expect(self.view.modalStackIsArgument === AutofillInstructionsNavigationController.self).to(beTrue())
                                    expect(self.view.startModalStackArgument).to(beNil())
                                }
                            }
                        }

                    }
                }

                describe("ExternalWebsiteRouteActions") {

                }

                describe("telemetry") {
                    let action = CopyAction(text: "somethin", field: .password, itemID: "fsdsdfsf", actionType: .tap) as TelemetryAction

                    describe("when usage data can be recorded") {
                        beforeEach {
                            self.userDefaultStore.recordUsageStub.onNext(true)
                            self.telemetryStore.telemetryStub.onNext(action)
                        }

                        it("passes all telemetry actions through to the telemetryactionhandler") {
                            expect(self.telemetryActionHandler.telemetryListener.events.last!.value.element!.eventMethod).to(equal(action.eventMethod))
                            expect(self.telemetryActionHandler.telemetryListener.events.last!.value.element!.eventObject).to(equal(action.eventObject))
                        }

                        it("enables adjust") {
                            expect(self.adjustManager.enabledValue).to(beTrue())
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

                        it("disables adjust") {
                            expect(self.adjustManager.enabledValue).to(beFalse())
                        }
                    }
                }
                describe("usage") {
                    describe("when usage data can be recorded") {
                        beforeEach {
                            self.userDefaultStore.recordUsageStub.onNext(true)
                            self.sentryManager.setup(sendUsageData: true)
                        }

                        it("sends data to Sentry") {
                            expect(self.sentryManager.setupCalled).to(equal(true))
                        }
                        it("sends data to Adjust") {
                            // TODO: add Adjust spec
                        }
                    }

                    describe("when usage data cannot be recorded") {
                        beforeEach {
                            self.userDefaultStore.recordUsageStub.onNext(false)
                            self.sentryManager.setup(sendUsageData: false)
                        }

                        it("does not send data to Sentry") {
                            expect(self.sentryManager.setupCalled).to(equal(false))
                        }
                        it("does not send data to Adjust") {
                            // TODO: add Adjust spec
                        }
                    }
                }

                describe("life cycle actions") {
                    describe("enters background") {
                        beforeEach {
                            self.lifecycleStore.filterStub.onNext(LifecycleAction.background)
                        }

                        it("sets privacy screen") {
                            expect(self.view.startModalStackArgument is PrivacyView).to(beTrue())
                        }
                    }

                    describe("enters foreground") {
                        beforeEach {
                            self.view.modalStackIsVar = true
                            self.lifecycleStore.filterStub.onNext(LifecycleAction.foreground)
                        }

                        it("sets privacy screen") {
                            expect(self.view.dismissModalCalled).to(beTrue())
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

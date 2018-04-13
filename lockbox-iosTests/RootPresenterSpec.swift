/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import UIKit

@testable import Lockbox

enum RootPresenterSharedExample: String {
    case NoLoginOrInitialize, NoUnlockOrList, EmptyProfileInfo, EmptyScopedKey
}

enum RootPresenterSharedExampleVar: String {
    case scopedKey, profileInfo, initialized, locked, opened
}

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
        var startModalStackArgument: UINavigationController.Type?
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

        func startModalStack<T: UINavigationController>(_ type: T.Type) {
            self.startModalStackArgument = type
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

    class FakeUserInfoStore: UserInfoStore {
        let profileInfoSubject = PublishSubject<ProfileInfo?>()
        let oauthInfoSubject = PublishSubject<OAuthInfo?>()
        let scopedKeySubject = PublishSubject<String?>()

        override var profileInfo: Observable<ProfileInfo?> {
            return self.profileInfoSubject.asObservable()
        }
        override var oauthInfo: Observable<OAuthInfo?> {
            return self.oauthInfoSubject.asObservable()
        }
        override var scopedKey: Observable<String?> {
            return self.scopedKeySubject.asObservable()
        }
    }

    class FakeDataStore: DataStore {
        let initSubject = PublishSubject<Bool>()
        let lockedSubject = PublishSubject<Bool>()
        let openedSubject = PublishSubject<Bool>()

        override var onInitialized: Observable<Bool> {
            return initSubject.asObservable()
        }
        override var onLocked: Observable<Bool> {
            return lockedSubject.asObservable()
        }
        override var onOpened: Observable<Bool> {
            return openedSubject.asObservable()
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeArgument = action
        }
    }

    class FakeDataStoreActionHandler: DataStoreActionHandler {
        var updateInitializedCalled = false
        var updateLockedCalled = false
        var initializeScopedKey: String?
        var openUID: String?
        var unlockScopedKey: String?

        override func updateInitialized() {
            self.updateInitializedCalled = true
        }

        override func updateLocked() {
            self.updateLockedCalled = true
        }

        override func initialize(scopedKey: String) {
            self.initializeScopedKey = scopedKey
        }

        override func open(uid: String) {
            self.openUID = uid
        }

        override func unlock(scopedKey: String) {
            self.unlockScopedKey = scopedKey
        }
    }

    private var view: FakeRootView!
    private var routeStore: FakeRouteStore!
    private var userInfoStore: FakeUserInfoStore!
    private var dataStore: FakeDataStore!
    private var routeActionHandler: FakeRouteActionHandler!
    private var dataStoreActionHandler: FakeDataStoreActionHandler!
    var subject: RootPresenter!

    override func spec() {
        describe("RootPresenter") {
            beforeEach {
                self.view = FakeRootView()
                self.routeStore = FakeRouteStore()
                self.userInfoStore = FakeUserInfoStore()
                self.dataStore = FakeDataStore()
                self.routeActionHandler = FakeRouteActionHandler()
                self.dataStoreActionHandler = FakeDataStoreActionHandler()
                self.subject = RootPresenter(
                        view: self.view,
                        routeStore: self.routeStore,
                        userInfoStore: self.userInfoStore,
                        dataStore: self.dataStore,
                        routeActionHandler: self.routeActionHandler,
                        dataStoreActionHandler: self.dataStoreActionHandler
                )
            }

            it("requests update for initialized & locked values immediately") {
                expect(self.dataStoreActionHandler.updateInitializedCalled).to(beTrue())
                expect(self.dataStoreActionHandler.updateLockedCalled).to(beTrue())
            }

            describe("when getting an empty profile info object, regardless of opened value") {
                sharedExamples(RootPresenterSharedExample.EmptyProfileInfo.rawValue) { context in
                    it("starts the login flow") {
                        let info = context()[RootPresenterSharedExampleVar.profileInfo.rawValue] as? ProfileInfo
                        let opened = context()[RootPresenterSharedExampleVar.opened.rawValue] as! Bool
                        self.advance(profileInfo: info, opened: opened)

                        expect(self.routeActionHandler.invokeArgument).notTo(beNil())
                        let argument = self.routeActionHandler.invokeArgument as! LoginRouteAction
                        expect(argument).to(equal(LoginRouteAction.welcome))
                        expect(self.dataStoreActionHandler.openUID).to(beNil())
                        expect(self.dataStoreActionHandler.initializeScopedKey).to(beNil())
                    }
                }

                itBehavesLike(RootPresenterSharedExample.EmptyProfileInfo.rawValue) {
                    [
                        RootPresenterSharedExampleVar.opened.rawValue: true
                    ]
                }

                itBehavesLike(RootPresenterSharedExample.EmptyProfileInfo.rawValue) {
                    [
                        RootPresenterSharedExampleVar.opened.rawValue: false
                    ]
                }
            }

            describe("getting a populated profile info object and the datastore is opened") {
                let uid = "fsdsfdfsd"

                beforeEach {
                    self.advance(profileInfo: ProfileInfo.Builder().uid(uid).build(), opened: true)
                }

                it("does nothing") {
                    expect(self.routeActionHandler.invokeArgument).to(beNil())
                    expect(self.dataStoreActionHandler.openUID).to(beNil())
                    expect(self.dataStoreActionHandler.initializeScopedKey).to(beNil())
                }
            }

            describe("getting an empty profile info object and the datastore is not opened") {
                let uid = "fsdsfdfsd"

                beforeEach {
                    self.advance(profileInfo: ProfileInfo.Builder().uid(uid).build(), opened: false)
                }

                it("dispatches the open action and displays the list") {
                    let argument = self.routeActionHandler.invokeArgument as! MainRouteAction
                    expect(argument).to(equal(MainRouteAction.list))
                    expect(self.dataStoreActionHandler.openUID).to(equal(uid))
                    expect(self.dataStoreActionHandler.initializeScopedKey).to(beNil())
                }
            }

            describe("when getting an empty scoped key object, regardless of initialized value OR populated scoped key & a positive initialized value") { // swiftlint:disable:this line_length
                sharedExamples(RootPresenterSharedExample.EmptyScopedKey.rawValue) { context in
                    it("does nothing") {
                        let scopedKey = context()[RootPresenterSharedExampleVar.scopedKey.rawValue] as? String
                        let initialized = context()[RootPresenterSharedExampleVar.initialized.rawValue] as! Bool
                        self.advance(scopedKey: scopedKey, initialized: initialized)

//                        expect(self.routeActionHandler.invokeArgument).to(beNil())
                        expect(self.dataStoreActionHandler.openUID).to(beNil())
                        expect(self.dataStoreActionHandler.initializeScopedKey).to(beNil())
                    }
                }

                itBehavesLike(RootPresenterSharedExample.EmptyScopedKey.rawValue) {
                    [
                        RootPresenterSharedExampleVar.initialized.rawValue: true
                    ]
                }

                itBehavesLike(RootPresenterSharedExample.EmptyScopedKey.rawValue) {
                    [
                        RootPresenterSharedExampleVar.initialized.rawValue: false
                    ]
                }

                itBehavesLike(RootPresenterSharedExample.EmptyScopedKey.rawValue) {
                    [
                        RootPresenterSharedExampleVar.initialized.rawValue: true,
                        RootPresenterSharedExampleVar.scopedKey.rawValue: "sdflkjsdfhjksdfkjhsdfhjksdf"
                    ]
                }
            }

            describe("when getting a populated scoped key object & the datastore is not initialized") {
                let scopedKey = "bljlkadsfljkafdsljk"
                beforeEach {
                    self.advance(scopedKey: scopedKey, initialized: false)
                }

                it("dispatches the initialized() action") {
                    expect(self.routeActionHandler.invokeArgument).to(beNil())
                    expect(self.dataStoreActionHandler.openUID).to(beNil())
                    expect(self.dataStoreActionHandler.initializeScopedKey).to(equal(scopedKey))
                }
            }

            describe("when getting a populated scoped key object & a locked datastore") {
                let scopedKey = "fsdljksdfjklfsdljksd"
                beforeEach {
                    self.dataStore.initSubject.onNext(true)
                    self.advance(scopedKey: scopedKey, locked: true)
                }

                it("unlocks the datastore") {
                    expect(self.dataStoreActionHandler.unlockScopedKey).to(equal(scopedKey))
                }
            }

            describe("all other cases for scoped key & locked values") {
                sharedExamples(RootPresenterSharedExample.NoUnlockOrList.rawValue) { context in
                    it("does nothing") {
                        let scopedKey = context()[RootPresenterSharedExampleVar.scopedKey.rawValue] as? String
                        let locked = context()[RootPresenterSharedExampleVar.locked.rawValue] as! Bool

                        self.advance(scopedKey: scopedKey, locked: locked)
                        expect(self.dataStoreActionHandler.unlockScopedKey).to(beNil())
                        expect(self.routeActionHandler.invokeArgument).to(beNil())
                    }
                }

                itBehavesLike(RootPresenterSharedExample.NoUnlockOrList.rawValue) {
                    [
                        RootPresenterSharedExampleVar.locked.rawValue: false
                    ]
                }

                itBehavesLike(RootPresenterSharedExample.NoUnlockOrList.rawValue) {
                    [
                        RootPresenterSharedExampleVar.scopedKey.rawValue: "meow",
                        RootPresenterSharedExampleVar.locked.rawValue: false
                    ]
                }

                itBehavesLike(RootPresenterSharedExample.NoUnlockOrList.rawValue) {
                    [
                        RootPresenterSharedExampleVar.locked.rawValue: true
                    ]
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
                            self.view.modalStackIsVar = true
                        }

                        describe(".list") {
                            describe("when the top view is the list view") {
                                beforeEach {
                                    self.view.modalViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.list)
                                }

                                it("dismisses no modals") {
                                    expect(self.view.dismissModalCalled).to(beFalse())
                                }

                                it("does not start the setting stack") {
                                    expect(self.view.modalStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startModalStackArgument).to(beNil())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.modalViewIsArgument === SettingListView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(beNil())
                                }
                            }

                            describe("when the top view is not the list view") {
                                beforeEach {
                                    self.view.modalViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.list)
                                }

                                it("dismisses no modals") {
                                    expect(self.view.dismissModalCalled).to(beFalse())
                                }

                                it("does not start the setting stack") {
                                    expect(self.view.modalStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startModalStackArgument).to(beNil())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.modalViewIsArgument === SettingListView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.list))
                                }
                            }
                        }

                        describe(".account") {
                            describe("when the top view is the account view") {
                                beforeEach {
                                    self.view.modalViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.account)
                                }

                                it("dismisses no modals") {
                                    expect(self.view.dismissModalCalled).to(beFalse())
                                }

                                it("does not start the setting stack") {
                                    expect(self.view.modalStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startModalStackArgument).to(beNil())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.modalViewIsArgument === AccountSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(beNil())
                                }
                            }

                            describe("when the top view is not the account view") {
                                beforeEach {
                                    self.view.modalViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.account)
                                }

                                it("dismisses no modals") {
                                    expect(self.view.dismissModalCalled).to(beFalse())
                                }

                                it("does not start the setting stack") {
                                    expect(self.view.modalStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.account))
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.modalViewIsArgument === AccountSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.account))
                                }
                            }
                        }
                    }

                    describe("if the setting stack is not already displayed") {
                        beforeEach {
                            self.view.modalStackIsVar = false
                        }

                        describe(".list") {
                            describe("when the top view is the list view") {
                                beforeEach {
                                    self.view.modalViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.list)
                                }

                                it("dismisses no modals") {
                                    expect(self.view.dismissModalCalled).to(beFalse())
                                }

                                it("starts the setting stack") {
                                    expect(self.view.modalStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startModalStackArgument === SettingNavigationController.self).to(beTrue())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.modalViewIsArgument === SettingListView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(beNil())
                                }
                            }

                            describe("when the top view is not the list view") {
                                beforeEach {
                                    self.view.modalViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.list)
                                }

                                it("dismisses no modals") {
                                    expect(self.view.dismissModalCalled).to(beFalse())
                                }

                                it("starts the setting stack") {
                                    expect(self.view.modalStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startModalStackArgument === SettingNavigationController.self).to(beTrue())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.modalViewIsArgument === SettingListView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.list))
                                }
                            }
                        }

                        describe(".account") {
                            describe("when the top view is the account view") {
                                beforeEach {
                                    self.view.modalViewIsVar = true
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.account)
                                }

                                it("dismisses no modals") {
                                    expect(self.view.dismissModalCalled).to(beFalse())
                                }

                                it("starts the setting stack") {
                                    expect(self.view.modalStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startModalStackArgument === SettingNavigationController.self).to(beTrue())
                                }

                                it("does not push a new setting view argument") {
                                    expect(self.view.modalViewIsArgument === AccountSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(beNil())
                                }
                            }

                            describe("when the top view is not the account view") {
                                beforeEach {
                                    self.view.modalViewIsVar = false
                                    self.routeStore.onRouteSubject.onNext(SettingRouteAction.account)
                                }

                                it("dismisses no modals") {
                                    expect(self.view.dismissModalCalled).to(beFalse())
                                }

                                it("starts the setting stack") {
                                    expect(self.view.modalStackIsArgument === SettingNavigationController.self).to(beTrue())
                                    expect(self.view.startModalStackArgument === SettingNavigationController.self).to(beTrue())
                                }

                                it("pushes a new setting view argument") {
                                    expect(self.view.modalViewIsArgument === AccountSettingView.self).to(beTrue())
                                    expect(self.view.pushSettingViewArgument).to(equal(SettingRouteAction.account))
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func advance(profileInfo: ProfileInfo?, opened: Bool) {
        self.userInfoStore.profileInfoSubject.onNext(profileInfo)
        self.dataStore.openedSubject.onNext(opened)
    }

    private func advance(scopedKey: String?, initialized: Bool) {
        self.userInfoStore.scopedKeySubject.onNext(scopedKey)
        self.dataStore.initSubject.onNext(initialized)
    }

    private func advance(scopedKey: String?, locked: Bool) {
        self.userInfoStore.scopedKeySubject.onNext(scopedKey)
        self.dataStore.lockedSubject.onNext(locked)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Quick
import Nimble

@testable import Lockbox

class RootViewSpec: QuickSpec {
    class FakeRootPresenter: RootPresenter {
        var onViewReadyCalled = false

        override func onViewReady() {
            self.onViewReadyCalled = true
        }
    }

    class FakeViewFactory: ViewFactory {
        override func make<T>(_ type: T.Type) -> UIViewController where T : UIViewController {
            switch type {
            case is FxAView.Type:
                return FakeFxAView()
            default:
                return UIViewController()
            }
        }

        override func make(storyboardName: String, identifier: String) -> UIViewController {
//            switch storyboardName {
//            case "OnboardingConfirmation":
//                return OnboardingConfirmationView(coder: NSCoder()) ?? UIViewController()
//            default:
                return UIViewController()
//            }
        }
    }

    private var presenter: FakeRootPresenter!
    var subject: RootView!
    var viewFactory: ViewFactory!

    override func spec() {
        let window = UIWindow()

        describe("RootView") {
            beforeEach {
                self.viewFactory = FakeViewFactory()
                self.subject = RootView(viewFactory: self.viewFactory)
                self.presenter = FakeRootPresenter(view: self.subject)
                self.subject.presenter = self.presenter

                window.rootViewController = self.subject
                window.makeKeyAndVisible()
            }

            it("informs the presenter on view load") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            describe("mainStackIs") {
                describe("without displaying a stack") {
                    it("returns false") {
                        expect(self.subject.mainStackIs(MainNavigationController.self)).to(beFalse())
                    }
                }

                describe("displaying a stack") {
                    beforeEach {
                        self.subject.startMainStack(MainNavigationController.self)
                    }

                    it("returns true") {
                        expect(self.subject.mainStackIs(MainNavigationController.self)).to(beTrue())
                    }
                }
            }

            describe("modalStackIs") {
                describe("without displaying a modal stack") {
                    it("returns false") {
                        expect(self.subject.modalStackIs(SettingNavigationController.self)).to(beFalse())
                    }
                }

                describe("displaying an initialized navigation controller") {
                    beforeEach {
                        self.subject.startMainStack(MainNavigationController.self)
                        self.subject.startModalStack(SettingNavigationController())
                    }

                    it("returns true") {
                        expect(self.subject.modalStackIs(SettingNavigationController.self)).to(beTrue())
                    }
                }
            }

            describe("pushing login views") {
                describe("login") {
                    beforeEach {
                        self.subject.startMainStack(LoginNavigationController.self)
                        self.subject.pushLoginView(view: LoginRouteAction.welcome)
                    }

                    it("makes a loginview the top view") {
                        expect(self.subject.topViewIs(WelcomeView.self)).to(beTrue())
                    }
                }

                describe("fxa") {
                    beforeEach {
                        self.subject.startMainStack(LoginNavigationController.self)
                        self.subject.pushLoginView(view: LoginRouteAction.fxa)
                    }

                    it("makes an fxaview the top view") {
                        expect(self.subject.topViewIs(FxAView.self)).to(beTrue())
                    }
                }

                describe("onboardingConfirmation") {
                    beforeEach {
                        self.subject.startMainStack(LoginNavigationController.self)
                        self.subject.pushLoginView(view: LoginRouteAction.onboardingConfirmation)
                    }

                    it("makes the onboardingconfirmation the top view") {
                        expect(self.subject.topViewIs(OnboardingConfirmationView.self)).to(beTrue())
                    }
                }

                describe("autofillOnboarding") {
                    beforeEach {
                        self.subject.startMainStack(LoginNavigationController.self)
                        self.subject.pushLoginView(view: LoginRouteAction.autofillOnboarding)
                    }

                    it("makes the autofillOnboarding the top view") {
                        expect(self.subject.topViewIs(AutofillOnboardingView.self)).to(beTrue())
                    }
                }

                describe("autofillInstructions") {
                    beforeEach {
                        self.subject.startMainStack(LoginNavigationController.self)
                        self.subject.pushLoginView(view: LoginRouteAction.autofillInstructions)
                    }

                    it("makes the autofillInsutrctions the top view") {
                        expect(self.subject.topViewIs(AutofillInstructionsView.self)).to(beTrue())
                    }
                }
            }

            describe("displaying main stack after login stack") {
                beforeEach {
                    self.subject.startMainStack(LoginNavigationController.self)
                    self.subject.startMainStack(MainNavigationController.self)
                }

                it("displays the main stack only") {
                    expect(self.subject.mainStackIs(LoginNavigationController.self)).to(beFalse())
                    expect(self.subject.mainStackIs(MainNavigationController.self)).to(beTrue())
                }
            }

            describe("pushing main views") {
                describe("list") {
                    beforeEach {
                        self.subject.startMainStack(MainNavigationController.self)
                        self.subject.pushMainView(view: .list)
                    }

                    it("makes a listview the top view") {
                        expect(self.subject.topViewIs(ItemListView.self)).to(beTrue())
                    }
                }

                describe("detail") {
                    beforeEach {
                        self.subject.startMainStack(MainNavigationController.self)
                        self.subject.pushMainView(view: .detail(itemId: "dffsdfs"))
                    }

                    it("makes a detailview the top view") {
                        expect(self.subject.topViewIs(ItemDetailView.self)).to(beTrue())
                    }
                }
            }

            describe("pushing settings views") {
                beforeEach {
                    self.subject.startMainStack(SettingNavigationController.self)
                }

                describe("list") {
                    beforeEach {
                        self.subject.pushSettingView(view: .list)
                    }

                    it("makes the list view the top view of the modal stack") {
                        expect(self.subject.topViewIs(SettingListView.self)).to(beTrue())
                    }
                }

                describe("account") {
                    beforeEach {
                        self.subject.pushSettingView(view: .account)
                    }

                    it("makes the account view the top view of the modal stack") {
                        expect(self.subject.topViewIs(AccountSettingView.self)).to(beTrue())
                    }
                }

                describe("autolock") {
                    beforeEach {
                        self.subject.pushSettingView(view: .autoLock)
                    }

                    it("makes the autolock view the top view of the modal stack") {
                        expect(self.subject.topViewIs(AutoLockSettingView.self)).to(beTrue())
                    }
                }

                describe("autofillInsturctions") {
                    beforeEach {
                        self.subject.pushSettingView(view: .autofillInstructions)
                    }

                    it("makes the autofill instructions view the new modal") {
                        expect(self.subject.topViewIs(AutofillInstructionsView.self)).to(beTrue())
                    }
                }
            }
        }
    }
}

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
        var isAArgument: UIViewController?
        var isAReturnValue: Bool = true

        var makeTypeArgument: UIViewController.Type?
        var makeStoryboardArgument: String?
        var makeIdentifierArgument: String?

        override func make<T>(_ type: T.Type) -> UIViewController where T: UIViewController {
            self.makeTypeArgument = type
            return type is UINavigationController.Type ? UINavigationController() : UIViewController()
        }

        override func make(storyboardName: String, identifier: String) -> UIViewController {
            self.makeStoryboardArgument = storyboardName
            self.makeIdentifierArgument = identifier
            return UIViewController()
        }
    }

    private var presenter: FakeRootPresenter!
    var subject: RootView!
    var viewFactory: FakeViewFactory!

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

                    it("buids the navigation controller") {
                        expect(self.viewFactory.makeTypeArgument === MainNavigationController.self).to(beTrue())
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

                    it("builds the navigation controller") {
                        expect(self.viewFactory.makeTypeArgument === MainNavigationController.self).to(beTrue())
                    }
                }
            }

            describe("pushing login views") {
                describe("login") {
                    beforeEach {
                        self.subject.startMainStack(LoginNavigationController.self)
                        self.subject.pushLoginView(view: LoginRouteAction.welcome)
                    }

                    it("builds a navigation controller") {
                        expect(self.viewFactory.makeTypeArgument === LoginNavigationController.self).to(beTrue())
                    }
                }

                describe("fxa") {
                    beforeEach {
                        self.subject.startMainStack(LoginNavigationController.self)
                        self.subject.pushLoginView(view: LoginRouteAction.fxa)
                    }

                    it("makes an fxaview view controller") {
                        expect(self.viewFactory.makeTypeArgument === FxAView.self).to(beTrue())
                    }
                }

                describe("onboardingConfirmation") {
                    beforeEach {
                        self.subject.startMainStack(LoginNavigationController.self)
                        self.subject.pushLoginView(view: LoginRouteAction.onboardingConfirmation)
                    }

                    it("makes the onboardingconfirmation view controller") {
                        expect(self.viewFactory.makeStoryboardArgument).to(equal("OnboardingConfirmation"))
                        expect(self.viewFactory.makeIdentifierArgument).to(equal("onboardingconfirmation"))
                    }
                }

                describe("autofillOnboarding") {
                    beforeEach {
                        self.subject.startMainStack(LoginNavigationController.self)
                        self.subject.pushLoginView(view: LoginRouteAction.autofillOnboarding)
                    }

                    it("makes the autofillOnboarding view controller") {
                        expect(self.viewFactory.makeStoryboardArgument).to(equal("AutofillOnboarding"))
                        expect(self.viewFactory.makeIdentifierArgument).to(equal("autofillonboarding"))
                    }
                }

                describe("autofillInstructions") {
                    beforeEach {
                        self.subject.startMainStack(LoginNavigationController.self)
                        self.subject.pushLoginView(view: LoginRouteAction.autofillInstructions)
                    }

                    it("makes the autofillInsutrctions view controller") {
                        expect(self.viewFactory.makeStoryboardArgument).to(equal("SetupAutofill"))
                        expect(self.viewFactory.makeIdentifierArgument).to(equal("autofillinstructions"))
                    }
                }
            }

            describe("pushing main views") {
                describe("list") {
                    beforeEach {
                        self.subject.startMainStack(MainNavigationController.self)
                        self.subject.pushMainView(view: .list)
                    }

                    it("only makes the view controller") {
                        expect(self.viewFactory.makeTypeArgument == MainNavigationController.self).to(beTrue())
                        expect(self.viewFactory.makeStoryboardArgument).to(beNil())
                    }
                }

                describe("detail") {
                    beforeEach {
                        self.subject.startMainStack(MainNavigationController.self)
                        self.subject.pushMainView(view: .detail(itemId: "dffsdfs"))
                    }

                    it("makes a detailview view controller") {
                        expect(self.viewFactory.makeStoryboardArgument).to(equal("ItemDetail"))
                        expect(self.viewFactory.makeIdentifierArgument).to(equal("itemdetailview"))
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

                    it("only makes the navigation controller") {
                        expect(self.viewFactory.makeStoryboardArgument).to(beNil())
                        expect(self.viewFactory.makeTypeArgument === SettingNavigationController.self).to(beTrue())
                    }
                }

                describe("account") {
                    beforeEach {
                        self.subject.pushSettingView(view: .account)
                    }

                    it("makes the account view") {
                        expect(self.viewFactory.makeStoryboardArgument).to(equal("AccountSetting"))
                        expect(self.viewFactory.makeIdentifierArgument).to(equal("accountsetting"))
                    }
                }

                describe("autolock") {
                    beforeEach {
                        self.subject.pushSettingView(view: .autoLock)
                    }

                    it("makes the autolock view") {
                        expect(self.viewFactory.makeTypeArgument === AutoLockSettingView.self).to(beTrue())
                    }
                }

                describe("autofillInsturctions") {
                    beforeEach {
                        self.subject.pushSettingView(view: .autofillInstructions)
                    }

                    it("makes the autofill insturctions view") {
                        expect(self.viewFactory.makeStoryboardArgument).to(equal("SetupAutofill"))
                        expect(self.viewFactory.makeIdentifierArgument).to(equal("autofillinstructions"))
                    }
                }
            }
        }
    }
}

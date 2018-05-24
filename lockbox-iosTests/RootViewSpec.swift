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

    private var presenter: FakeRootPresenter!
    var subject: RootView!

    override func spec() {
        let window = UIWindow()

        describe("RootView") {
            beforeEach {
                self.subject = RootView()
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

                describe("displaying the setting stack") {
                    beforeEach {
                        self.subject.startMainStack(MainNavigationController.self)
                        self.subject.startModalStack(SettingNavigationController.self)
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
                        expect(self.subject.topViewIs(FxAView.self)).toEventually(beTrue(), timeout: 20)
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
                        expect(self.subject.topViewIs(ItemDetailView.self)).toEventually(beTrue(), timeout: 20)
                    }
                }

                describe("learnMore") {
                    beforeEach {
                        self.subject.startMainStack(MainNavigationController.self)
                        self.subject.pushMainView(view: .learnMore)
                    }

                    it("makes a detailview the top view") {
                        expect(self.subject.topViewIs(StaticURLWebView.self)).toEventually(beTrue(), timeout: 20)
                    }
                }
            }

            describe("pushing settings views") {
                beforeEach {
                    self.subject.startMainStack(MainNavigationController.self)

                    expect(self.subject.mainStackIs(MainNavigationController.self)).toEventually(beTrue())
                    self.subject.startModalStack(SettingNavigationController.self)
                }

                afterEach {
                    self.subject.pushMainView(view: .list)
                }

                describe("list") {
                    beforeEach {
                        self.subject.pushSettingView(view: .list)
                    }

                    it("makes the list view the top view of the modal stack") {
                        expect(self.subject.modalViewIs(SettingListView.self)).to(beTrue())
                    }
                }

                describe("account") {
                    beforeEach {
                        self.subject.pushSettingView(view: .account)
                    }

                    it("makes the account view the top view of the modal stack") {
                        expect(self.subject.modalViewIs(AccountSettingView.self)).toEventually(beTrue(), timeout: 20)
                    }
                }

                describe("autolock") {
                    beforeEach {
                        self.subject.pushSettingView(view: .autoLock)
                    }

                    it("makes the autolock view the top view of the modal stack") {
                        expect(self.subject.modalViewIs(AutoLockSettingView.self)).toEventually(beTrue(), timeout: 20)
                    }
                }

                describe("provide feedback") {
                    beforeEach {
                        self.subject.pushSettingView(view: .provideFeedback)
                    }

                    it("makes the web view the top view of the modal stack") {
                        expect(self.subject.modalViewIs(StaticURLWebView.self)).toEventually(beTrue(), timeout: 20)
                    }
                }

                describe("faq") {
                    beforeEach {
                        self.subject.pushSettingView(view: .faq)
                    }

                    it("makes the faq view the top view of the modal stack") {
                        expect(self.subject.modalViewIs(StaticURLWebView.self)).toEventually(beTrue(), timeout: 20)
                    }
                }
            }
        }
    }
}

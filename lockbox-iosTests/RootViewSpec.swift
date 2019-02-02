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

    class SVDelegate: UISplitViewControllerDelegate {

    }

    private var presenter: FakeRootPresenter!
    var subject: RootView!
    private var svDelegate: SVDelegate!
    var viewFactory: ViewFactory!

    override func spec() {
        let window = UIWindow()

        describe("RootView") {
            beforeEach {
                self.subject = RootView()
                self.svDelegate = SVDelegate()
                self.presenter = FakeRootPresenter(view: self.subject)
                self.viewFactory = ViewFactory()
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
                        self.subject.startMainStack(MainNavigationController())
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
                        self.subject.startMainStack(MainNavigationController())
                        self.subject.startModalStack(SettingNavigationController())
                    }

                    it("returns true") {
                        expect(self.subject.modalStackIs(SettingNavigationController.self)).to(beTrue())
                    }
                }
            }

            describe("startMainStack") {
                describe("LoginNavigationController") {
                    beforeEach {
                        self.subject.startMainStack(LoginNavigationController())
                    }

                    it("makes a loginnav the stack") {
                        expect(self.subject.mainStackIs(LoginNavigationController.self)).to(beTrue())
                    }

                    it("sets the welcome view as the top view") {
                        expect(self.subject.topViewIs(WelcomeView.self)).to(beTrue())
                    }
                }
            }

            describe("startModalStack") {
                describe("SettingNavigationController") {
                    beforeEach {
                        self.subject.startMainStack(MainNavigationController())
                        self.subject.startModalStack(SettingNavigationController())
                    }

                    it("makes the settings controller the modal view") {
                        expect(self.subject.modalViewIs(SettingListView.self)).to(beTrue())
                    }

                    it("makes the settings nav the stack") {
                        expect(self.subject.modalStackIs(SettingNavigationController.self)).to(beTrue())
                    }
                }
            }

            describe("dismissModals") {
                beforeEach {
                    self.subject.startMainStack(MainNavigationController())
                    self.subject.startModalStack(SettingNavigationController())
                    expect(self.subject.modalStackIs(SettingNavigationController.self)).to(beTrue())
                    expect(self.subject.modalStackPresented).to(beTrue())
                    self.subject.dismissModals()
                }

                xit("modalStackPresented is false") {
                    expect(self.subject.modalStackPresented).to(beFalse())
                }

                xit("removes the modal stack") {
                    expect(self.subject.modalStackIs(SettingNavigationController.self)).to(beFalse())
                }
            }

            describe("pushing views") {
                beforeEach {
                    self.subject.startMainStack(MainNavigationController())
                    self.subject.push(view: self.viewFactory.make(storyboardName: "ItemList", identifier: "itemlist"))
                }

                it("sets the view to the list") {
                    expect(self.subject.topViewIs(ItemListView.self)).to(beTrue())
                }
            }

            if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
                describe("pushing sidebar views") {
                    beforeEach {
                        self.subject.startMainStack(SplitView(delegate: self.svDelegate))
                        self.subject.pushSidebar(view: self.viewFactory.make(storyboardName: "ItemList", identifier: "itemlist"))
                    }

                    it("sets the sidebar view to the list") {
                        expect(self.subject.sidebarViewIs(ItemListView.self)).to(beTrue())
                    }
                }

                describe("pushing detail views") {
                    beforeEach {
                        self.subject.startMainStack(SplitView(delegate: self.svDelegate))
                        self.subject.pushDetail(view: self.viewFactory.make(storyboardName: "ItemDetail", identifier: "itemdetailview"))
                    }

                    it("sets the detail view to the item detail screen") {
                        expect(self.subject.detailViewIs(ItemDetailView.self)).to(beTrue())
                    }
                }
            }

            describe("popView") {
                beforeEach {
                    self.subject.startMainStack(UINavigationController())
                    self.subject.push(view: self.viewFactory.make(storyboardName: "ItemList", identifier: "itemlist"))
                    self.subject.push(view: self.viewFactory.make(storyboardName: "ItemDetail", identifier: "itemdetailview"))
                    self.subject.push(view: self.viewFactory.make(storyboardName: "SettingList", identifier: "settinglist"))
                    expect(self.subject.topViewIs(SettingListView.self)).to(beTrue())
                    self.subject.popView()
                }

                it("removes only one view") {
                    expect(self.subject.topViewIs(ItemDetailView.self)).to(beTrue())
                }
            }

            describe("pop to root") {
                beforeEach {
                    self.subject.startMainStack(UINavigationController())
                    self.subject.push(view: self.viewFactory.make(storyboardName: "ItemList", identifier: "itemlist"))
                    self.subject.push(view: self.viewFactory.make(storyboardName: "ItemDetail", identifier: "itemdetailview"))
                    self.subject.push(view: self.viewFactory.make(storyboardName: "SettingList", identifier: "settinglist"))
                    expect(self.subject.topViewIs(SettingListView.self)).to(beTrue())
                    self.subject.popView()
                }

                it("removes only one view") {
                    expect(self.subject.topViewIs(ItemDetailView.self)).to(beTrue())
                }
            }
        }
    }
}

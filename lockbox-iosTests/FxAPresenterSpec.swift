/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Quick
import Nimble
import WebKit
import RxCocoa
import RxSwift
import RxTest

@testable import Lockbox

class FxAPresenterSpec: QuickSpec {
    class FakeFxAView: FxAViewProtocol {
        var loadRequestArgument: URLRequest?

        func loadRequest(_ urlRequest: URLRequest) {
            self.loadRequestArgument = urlRequest
        }

        func displayError(_ error: Error) {
        }
    }

    class FakeNavigationAction: WKNavigationAction {
        private var fakeRequest: URLRequest
        override var request: URLRequest {
            return self.fakeRequest
        }

        init(request: URLRequest) {
            self.fakeRequest = request
        }
    }

    class FakeFxAStore: FxAStore {
        var fakeFxADisplay = PublishSubject<FxADisplayAction>()

        override var fxADisplay: Observable<FxADisplayAction> {
            return fakeFxADisplay.asObservable()
        }
    }

    class FakeSettingActionHandler: SettingActionHandler {
        var invokeArgument: SettingAction?

        override func invoke(_ action: SettingAction) {
            self.invokeArgument = action
        }
    }

    class FakeFxAActionHandler: FxAActionHandler {
        var initiateFxAAuthenticationReceived = false
        var matchingRedirectURLComponentsArgument: URLComponents?

        override func initiateFxAAuthentication() {
            self.initiateFxAAuthenticationReceived = true
        }

        override func matchingRedirectURLReceived(components: URLComponents) {
            self.matchingRedirectURLComponentsArgument = components
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeArgument: RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeArgument = action
        }
    }

    private var view: FakeFxAView!
    private var fxaStore: FakeFxAStore!
    private var settingActionHandler: FakeSettingActionHandler!
    private var fxAActionHandler: FakeFxAActionHandler!
    private var routeActionHandler: FakeRouteActionHandler!
    var subject: FxAPresenter!

    override func spec() {

        describe("FxAPresenter") {
            beforeEach {
                self.view = FakeFxAView()
                self.fxaStore = FakeFxAStore()
                self.settingActionHandler = FakeSettingActionHandler()
                self.fxAActionHandler = FakeFxAActionHandler()
                self.routeActionHandler = FakeRouteActionHandler()
                self.subject = FxAPresenter(
                        view: self.view,
                        fxAActionHandler: self.fxAActionHandler,
                        settingActionHandler: self.settingActionHandler,
                        routeActionHandler: self.routeActionHandler,
                        fxaStore: self.fxaStore
                )
            }

            describe(".onViewReady()") {
                beforeEach {
                    self.subject.onViewReady()
                    UserDefaults.standard.set(false, forKey: SettingKey.locked.rawValue)
                }

                it("initiates fxa authentication") {
                    expect(self.fxAActionHandler.initiateFxAAuthenticationReceived).to(beTrue())
                }

                describe("receiving .loadInitialURL") {
                    let url = URL(string: "www.properurltoload.com/manystuffs?ihavequery")!
                    beforeEach {
                        self.fxaStore.fakeFxADisplay.onNext(FxADisplayAction.loadInitialURL(url: url))
                    }

                    it("tells the view to load the url") {
                        expect(self.view.loadRequestArgument).notTo(beNil())
                        expect(self.view.loadRequestArgument).to(equal(URLRequest(url: url)))
                    }
                }

                describe("when authenticating during the first run") {
                    beforeEach {
                        UserDefaults.standard.set(false, forKey: SettingKey.locked.rawValue)
                    }

                    describe("receiving .finishedFetchingUserInformation") {
                        beforeEach {
                            self.fxaStore.fakeFxADisplay.onNext(FxADisplayAction.finishedFetchingUserInformation)
                        }

                        it("tells the settings to unlock the application") {
                            expect(self.settingActionHandler.invokeArgument).to(equal(SettingAction.visualLock(locked: false)))
                        }

                        it("tells routing action handler to show the onboarding with biometrics screen") {
                            expect(self.routeActionHandler.invokeArgument).notTo(beNil())
                            let argument = self.routeActionHandler.invokeArgument as! LoginRouteAction
                            expect(argument).to(equal(LoginRouteAction.biometryOnboarding))
                        }
                    }
                }

                describe("when authenticating from lock") {
                    beforeEach {
                        UserDefaults.standard.set(true, forKey: SettingKey.locked.rawValue)
                    }

                    describe("receiving .finishedFetchingUserInformation") {
                        beforeEach {
                            self.fxaStore.fakeFxADisplay.onNext(FxADisplayAction.finishedFetchingUserInformation)
                        }

                        it("tells the settings to unlock the application") {
                            expect(self.settingActionHandler.invokeArgument).to(equal(SettingAction.visualLock(locked: false)))
                        }

                        it("tells routing action handler to show the listview") {
                            expect(self.routeActionHandler.invokeArgument).notTo(beNil())
                            let argument = self.routeActionHandler.invokeArgument as! MainRouteAction
                            expect(argument).to(equal(MainRouteAction.list))
                        }
                    }
                }

                describe("receiving any other fxa action") {
                    beforeEach {
                        self.fxaStore.fakeFxADisplay.onNext(FxADisplayAction.fetchingUserInformation)
                    }

                    it("does nothing") {
                        expect(self.routeActionHandler.invokeArgument).to(beNil())
                        expect(self.settingActionHandler.invokeArgument).to(beNil())
                        expect(self.view.loadRequestArgument).to(beNil())
                    }
                }
            }

            describe(".webViewRequest") {
                var decisionHandler: ((WKNavigationActionPolicy) -> Void)!
                var returnedPolicy: WKNavigationActionPolicy?

                beforeEach {
                    decisionHandler = { policy in
                        returnedPolicy = policy
                    }
                }

                describe("when called with a request URL that doesn't match the redirect URI") {
                    beforeEach {
                        let request = URLRequest(url: URL(string: "http://wwww.somefakewebsite.com")!)
                        self.subject.webViewRequest(
                                decidePolicyFor: FakeNavigationAction(request: request),
                                decisionHandler: decisionHandler
                        )
                    }

                    it("allows the navigation action") {
                        expect(returnedPolicy!).to(equal(WKNavigationActionPolicy.allow))
                    }
                }

                describe("when called with a request URL matching the redirect URI") {
                    var urlComponents = URLComponents()

                    beforeEach {
                        urlComponents.scheme = "https"
                        urlComponents.host = "mozilla-lockbox.github.io"
                        urlComponents.path = "/fxa/ios-redirect.html"

                        let request = URLRequest(url: urlComponents.url!)
                        self.subject.webViewRequest(
                                decidePolicyFor: FakeNavigationAction(request: request),
                                decisionHandler: decisionHandler
                        )
                    }

                    it("cancels the navigation action & tells the fxaactionhandler") {
                        expect(returnedPolicy!).to(equal(WKNavigationActionPolicy.cancel))
                        expect(self.fxAActionHandler.matchingRedirectURLComponentsArgument).notTo(beNil())
                        expect(self.fxAActionHandler.matchingRedirectURLComponentsArgument).to(equal(urlComponents))
                    }
                }
            }

            describe("onCancel") {
                beforeEach {
                    self.subject.onCancel.onNext(())
                }

                it("routes back to login") {
                    expect(self.routeActionHandler.invokeArgument).notTo(beNil())
                    let argument = self.routeActionHandler.invokeArgument as! LoginRouteAction
                    expect(argument).to(equal(LoginRouteAction.welcome))
                }
            }
        }
    }
}

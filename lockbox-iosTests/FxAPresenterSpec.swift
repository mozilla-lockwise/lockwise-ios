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

class FxAPresenterSpec : QuickSpec {
    class FakeFxAView : FxAViewProtocol {
        func dismiss() {

        }

        var loadRequestArgument:URLRequest?

        func loadRequest(_ urlRequest: URLRequest) {
            self.loadRequestArgument = urlRequest
        }

        func displayError(_ error: Error) {}
    }

    class FakeNavigationAction : WKNavigationAction {
        private var fakeRequest:URLRequest
        override var request:URLRequest {
            get {
                return self.fakeRequest
            }
        }

        init(request:URLRequest) {
            self.fakeRequest = request
        }
    }

    class FakeFxAStore: FxAStore {
        var fakeFxADisplay = PublishSubject<FxADisplayAction>()

        override var fxADisplay: Driver<FxADisplayAction> {
            return fakeFxADisplay.asDriver(onErrorJustReturn: .fetchingUserInformation)
        }
    }

    class FakeFxAActionHandler: FxAActionHandler {
        var initiateFxAAuthenticationReceived = false
        var matchingRedirectURLComponentsArgument:URLComponents?

        override func initiateFxAAuthentication() {
            self.initiateFxAAuthenticationReceived = true
        }

        override func matchingRedirectURLReceived(components: URLComponents) {
            self.matchingRedirectURLComponentsArgument = components
        }
    }

    class FakeRouteActionHandler: RouteActionHandler {
        var invokeArgument:RouteAction?

        override func invoke(_ action: RouteAction) {
            self.invokeArgument = action
        }
    }

    private var view:FakeFxAView!
    private var store:FakeFxAStore!
    private var fxAActionHandler:FakeFxAActionHandler!
    private var routeActionHandler:FakeRouteActionHandler!
    var subject:FxAPresenter!

    override func spec() {

        describe("FxAPresenter") {
            beforeEach {
                self.view = FakeFxAView()
                self.store = FakeFxAStore()
                self.fxAActionHandler = FakeFxAActionHandler()
                self.routeActionHandler = FakeRouteActionHandler()
                self.subject = FxAPresenter(
                        view: self.view,
                        fxAActionHandler: self.fxAActionHandler,
                        routeActionHandler: self.routeActionHandler,
                        store: self.store
                )
            }

            describe(".onViewReady()") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("receiving .loadInitialURL") {
                    let url = URL(string: "www.properurltoload.com/manystuffs?ihavequery")!
                    beforeEach {
                        self.store.fakeFxADisplay.onNext(FxADisplayAction.loadInitialURL(url: url))
                    }

                    it("initiates fxa authentication") {
                        expect(self.fxAActionHandler.initiateFxAAuthenticationReceived).to(beTrue())
                    }

                    it("tells the view to load the url") {
                        expect(self.view.loadRequestArgument).notTo(beNil())
                        expect(self.view.loadRequestArgument).to(equal(URLRequest(url: url)))
                    }
                }

                describe("receiving .finishedFetchingUserInformation") {
                    beforeEach {
                        self.store.fakeFxADisplay.onNext(FxADisplayAction.finishedFetchingUserInformation)
                    }

                    it("initiates fxa authentication") {
                        expect(self.fxAActionHandler.initiateFxAAuthenticationReceived).to(beTrue())
                    }

                    it("tells routing action handler to show the listview") {
                        expect(self.routeActionHandler.invokeArgument).notTo(beNil())
                        let argument = self.routeActionHandler.invokeArgument as! MainRouteAction
                        expect(argument).to(equal(MainRouteAction.list))
                    }
                }
            }

            describe(".webViewRequest") {
                var decisionHandler:((WKNavigationActionPolicy) -> Void)!
                var returnedPolicy:WKNavigationActionPolicy?

                beforeEach {
                    decisionHandler = { policy in
                        returnedPolicy = policy
                    }
                }

                describe("when called with a request URL that doesn't match the redirect URI") {
                    beforeEach {
                        let request = URLRequest(url: URL(string:"http://wwww.somefakewebsite.com")!)
                        self.subject.webViewRequest(decidePolicyFor: FakeNavigationAction(request:request), decisionHandler: decisionHandler)
                    }

                    it("allows the navigation action") {
                        expect(returnedPolicy!).to(equal(WKNavigationActionPolicy.allow))
                    }
                }

                describe("when called with a request URL matching the redirect URI") {
                    var urlComponents = URLComponents()

                    beforeEach {
                        urlComponents.scheme = "lockbox"
                        urlComponents.host = "redirect.ios"
                        urlComponents.path = "/"

                        let request = URLRequest(url: urlComponents.url!)
                        self.subject.webViewRequest(decidePolicyFor: FakeNavigationAction(request: request), decisionHandler: decisionHandler)
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

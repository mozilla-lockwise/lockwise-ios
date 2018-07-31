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
import Account
import SwiftyJSON

class FxAPresenterSpec: QuickSpec {
    class FakeFxAView: FxAViewProtocol {
        var loadRequestArgument: URLRequest?

        func loadRequest(_ urlRequest: URLRequest) {
            self.loadRequestArgument = urlRequest
        }
    }

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
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

    class FakeAccountActionHandler: AccountActionHandler {
        var invokeArgument: AccountAction?

        override func invoke(_ action: AccountAction) {
            self.invokeArgument = action
        }
    }

    class FakeAccountStore: AccountStore {
        let loginURLStub = PublishSubject<URL>()

        override var loginURL: Observable<URL> {
            return self.loginURLStub.asObservable()
        }
    }

    private var view: FakeFxAView!
    private var dispatcher: FakeDispatcher!
    private var accountActionHandler: FakeAccountActionHandler!
    private var accountStore: FakeAccountStore!
    var subject: FxAPresenter!

    override func spec() {

        describe("FxAPresenter") {
            beforeEach {
                self.view = FakeFxAView()
                self.dispatcher = FakeDispatcher()
                self.accountActionHandler = FakeAccountActionHandler()
                self.accountStore = FakeAccountStore()
                self.subject = FxAPresenter(
                        view: self.view,
                        dispatcher: self.dispatcher,
                        accountActionHandler: self.accountActionHandler,
                        accountStore: self.accountStore
                )
            }

            describe(".onViewReady()") {
                beforeEach {
                    self.subject.onViewReady()
                }

                it("tells the view to load the login URL") {
                    let url = URL(string: "https://www.mozilla.org")!
                    self.accountStore.loginURLStub.onNext(url)

                    expect(self.view.loadRequestArgument).to(equal(URLRequest(url: url)))
                }
            }

            describe("onClose") {
                beforeEach {
                    self.subject.onClose.onNext(())
                }

                it("routes back to login") {
                    expect(self.dispatcher.dispatchedActions).to(haveCount(1))
                    expect(self.dispatcher.dispatchedActions[0]).to(beAnInstanceOf(LoginRouteAction.self))
                    let argument = self.dispatcher.dispatchedActions[0] as! LoginRouteAction
                    expect(argument).to(equal(.welcome))
                }
            }

            describe("matchingRedirectURLReceived") {
                let url = URL(string: "https://www.mozilla.com")!

                beforeEach {
                    self.subject.matchingRedirectURLReceived(url)
                }

                it("invokes the oauth redirect, routes to onboarding, and sets onboarding status") {
                    expect(self.accountActionHandler.invokeArgument).to(equal(AccountAction.oauthRedirect(url: url)))

                    expect(self.dispatcher.dispatchedActions).to(haveCount(2))

                    expect(self.dispatcher.dispatchedActions[0]).to(beAnInstanceOf(OnboardingStatusAction.self))
                    let onboardingAction = self.dispatcher.dispatchedActions[0] as! OnboardingStatusAction
                    expect(onboardingAction.onboardingInProgress).to(beTrue())

                    expect(self.dispatcher.dispatchedActions[1]).to(beAnInstanceOf(LoginRouteAction.self))
                    let routeAction = self.dispatcher.dispatchedActions[1] as! LoginRouteAction
                    expect(routeAction).to(equal(.onboardingConfirmation))
                }
            }
        }
    }
}

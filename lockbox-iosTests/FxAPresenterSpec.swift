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
        var retryButtonStub = PublishSubject<Void>()
        var networkDisclaimerHiddenObserver: TestableObserver<Bool>!

        func loadRequest(_ urlRequest: URLRequest) {
            self.loadRequestArgument = urlRequest
        }

        var retryButtonTapped: Observable<Void> {
            return self.retryButtonStub
        }

        var networkDisclaimerHidden: AnyObserver<Bool> {
            return self.networkDisclaimerHiddenObserver.asObserver()
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

    class FakeAccountStore: AccountStore {
        let loginURLStub = PublishSubject<URL>()

        override var loginURL: Observable<URL> {
            return self.loginURLStub.asObservable()
        }
    }

    class FakeNetworkStore: NetworkStore {
        let connectedToNetworkStub = PublishSubject<Bool>()

        override var connectedToNetwork: Observable<Bool> {
            return self.connectedToNetworkStub.asObservable()
        }
    }

    private var view: FakeFxAView!
    private var dispatcher: FakeDispatcher!
    private var accountStore: FakeAccountStore!
    private var networkStore: FakeNetworkStore!
    private var credentialProviderStore: Any!
    var subject: FxAPresenter!
    private var scheduler = TestScheduler(initialClock: 0)

    override func spec() {

        describe("FxAPresenter") {
            beforeEach {
                self.view = FakeFxAView()
                self.view.networkDisclaimerHiddenObserver = self.scheduler.createObserver(Bool.self)

                self.dispatcher = FakeDispatcher()
                self.accountStore = FakeAccountStore()
                self.networkStore = FakeNetworkStore()

                if #available(iOS 12.0, *) {
                    self.credentialProviderStore = FakeCredentialProviderStore()
                    self.subject = FxAPresenter(
                        view: self.view,
                        dispatcher: self.dispatcher,
                        accountStore: self.accountStore,
                        networkStore: self.networkStore,
                        credentialProviderStore: self.credentialProviderStore as! CredentialProviderStore
                    )

                } else {
                    self.subject = FxAPresenter(
                            view: self.view,
                            dispatcher: self.dispatcher,
                            accountStore: self.accountStore,
                            networkStore: self.networkStore
                    )
                }
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

                describe("when the retry button is tapped") {
                    beforeEach {
                        self.view.retryButtonStub.onNext(())
                    }

                    it("dispatches the retry action") {
                        expect(self.dispatcher.dispatchedActions.last as? NetworkAction).to(equal(NetworkAction.retry))
                    }
                }

                describe("network connectivity") {
                    it("being connected hides the network disclaimer") {
                        self.networkStore.connectedToNetworkStub.onNext(true)
                        expect(self.view.networkDisclaimerHiddenObserver.events.last?.value.element).to(beTrue())
                    }

                    it("being disconnected shows the network disclaimer") {
                        self.networkStore.connectedToNetworkStub.onNext(false)
                        expect(self.view.networkDisclaimerHiddenObserver.events.last?.value.element).to(beFalse())
                    }
                }
            }

            describe("onClose") {
                beforeEach {
                    self.subject.onClose.onNext(())
                }

                it("routes back to login") {
                    let argument = self.dispatcher.dispatchedActions.popLast() as! LoginRouteAction
                    expect(argument).to(equal(.welcome))
                }
            }

            describe("matchingRedirectURLReceived") {
                let url = URL(string: "https://www.mozilla.com")!

                beforeEach {
                    if #available(iOS 12.0, *) {
                        (self.credentialProviderStore as! FakeCredentialProviderStore).stateToProvide.onNext(.NotAllowed)
                    }

                    self.subject.onViewReady()
                    self.subject.matchingRedirectURLReceived(url)
                }

                it("invokes the oauth redirect, routes to onboarding, and sets onboarding status") {
                    let accountAction = self.dispatcher.dispatchedActions.popLast() as! AccountAction
                    expect(accountAction).to(equal(.oauthRedirect(url: url)))

                    let routeAction = self.dispatcher.dispatchedActions.popLast() as! LoginRouteAction
                    if #available(iOS 12.0, *) {
                        expect(routeAction).to(equal(.autofillOnboarding))
                    } else {
                        expect(routeAction).to(equal(.onboardingConfirmation))
                    }

                    let onboardingAction = self.dispatcher.dispatchedActions.popLast() as! OnboardingStatusAction
                    expect(onboardingAction.onboardingInProgress).to(beTrue())
                }
            }
        }
    }
}

@available(iOS 12, *)
class FakeCredentialProviderStore: CredentialProviderStore {
    var stateToProvide = ReplaySubject<CredentialProviderStoreState>.create(bufferSize: 1)

    override var state: Observable<CredentialProviderStoreState> {
        return stateToProvide.asObservable()
    }
}

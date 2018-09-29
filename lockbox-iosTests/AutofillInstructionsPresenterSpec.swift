/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest

@testable import Lockbox

class AutofillInstructionsPresenterSpec: QuickSpec {
    class FakeAutofillInstructionsView: AutofillInstructionsViewProtocol {
        let finishButtonTapStub = PublishSubject<Void>()

        var finishButtonTapped: Observable<Void> {
            return finishButtonTapStub.asObserver()
        }

    }

    class FakeDispatcher: Dispatcher {
        var dispatchedActions: [Action] = []

        override func dispatch(action: Action) {
            self.dispatchedActions.append(action)
        }
    }

    private var view: FakeAutofillInstructionsView!
    private var dispatcher: FakeDispatcher!
    var subject: AutofillInstructionsPresenter!

    override func spec() {
        describe("AutofillInstrunctionsPresenter") {
            beforeEach {
                self.view = FakeAutofillInstructionsView()
                self.dispatcher = FakeDispatcher()
                self.subject = AutofillInstructionsPresenter(
                    view: self.view,
                    dispatcher: self.dispatcher
                )
            }

            describe("onViewReady") {
                beforeEach {
                    self.subject.onViewReady()
                }

                describe("onFinishButtonTapped") {
                    beforeEach {
                        self.view.finishButtonTapStub.onNext(())
                    }

                    it("routes to the SettingRouteAction.list") {
                        let settingRouteAction = self.dispatcher.dispatchedActions.popLast() as! SettingRouteAction
                        expect(settingRouteAction).to(equal(.list))
                    }
                }
            }
        }
    }
}

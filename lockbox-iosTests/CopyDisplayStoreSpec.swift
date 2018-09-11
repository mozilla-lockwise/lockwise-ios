/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift

@testable import Lockbox

class CopyDisplayStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    class FakePasteboard: UIPasteboard {
        var passedItems: [[String: Any]]?
        var options: [UIPasteboard.OptionsKey: Any]?

        override func setItems(_ items: [[String: Any]], options: [UIPasteboard.OptionsKey: Any]) {
            self.passedItems = items
            self.options = options
        }
    }

    private var dispatcher: FakeDispatcher!
    private var pasteboard: FakePasteboard!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: CopyDisplayStore!

    override func spec() {
        describe("CopyDisplayStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.pasteboard = FakePasteboard()
                self.subject = CopyDisplayStore(dispatcher: self.dispatcher, pasteboard: self.pasteboard)
            }

            describe("receiving copyactions") {
                let text = "myspecialtext"
                let fieldName = CopyField.password
                let action = CopyAction(text: text, field: fieldName, itemID: "dsdfssd")
                var fieldObserver = self.scheduler.createObserver(CopyField.self)

                beforeEach {
                    fieldObserver = self.scheduler.createObserver(CopyField.self)

                    self.subject.copyDisplay.drive(fieldObserver).disposed(by: self.disposeBag)

                    self.dispatcher.fakeRegistration.onNext(action)
                }

                it("adds the item to the pasteboard with item and timeout option") {
                    let expireDate = Date().addingTimeInterval(TimeInterval(Constant.number.copyExpireTimeSecs))

                    expect(self.pasteboard.passedItems![0][UIPasteboard.typeAutomatic] as? String).to(equal(text))
                    expect(self.pasteboard.options![UIPasteboard.OptionsKey.expirationDate] as! NSDate).to(beCloseTo(expireDate, within: 0.1))
                }

                it("pushes the copied field") {
                    expect(fieldObserver.events.last!.value.element).to(equal(fieldName))
                }
            }
        }
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift

@testable import Firefox_Lockbox

class DispatcherSpec: QuickSpec {
    private let scheduler = TestScheduler.init(initialClock: 0)
    private let disposeBag = DisposeBag()

    override func spec() {
        describe("dispatcher") {
            describe(".register and .dispatch") {
                let testObserver = self.scheduler.createObserver(Action.self)

                beforeEach {
                    Dispatcher.shared.register
                            .subscribe(testObserver)
                            .disposed(by: self.disposeBag)
                }

                it("pushes actions to registered observers") {
                    Dispatcher.shared.dispatch(action: ErrorAction(error: NSError(domain: "badness", code: -1)))

                    expect(testObserver.events.first).notTo(beNil())
                    let event = testObserver.events.first!.value.element as! ErrorAction
                    expect(event).to(matchErrorAction(ErrorAction(error: NSError(domain: "badness", code: -1))))
                }
            }
        }
    }
}

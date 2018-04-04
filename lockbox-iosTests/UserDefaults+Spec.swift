/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest
import RxCocoa

@testable import Lockbox

class UserDefaultSpec: QuickSpec {
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()

    override func spec() {
        describe("onLock") {
            var lockObserver = self.scheduler.createObserver(Bool.self)

            beforeEach {
                lockObserver = self.scheduler.createObserver(Bool.self)

                UserDefaults.standard.onLock
                        .subscribe(lockObserver)
                        .disposed(by: self.disposeBag)
            }

            it("pushes new values for the SettingKey to observers") {
                UserDefaults.standard.set(true, forKey: SettingKey.locked.rawValue)

                expect(lockObserver.events.last!.value.element).to(beTrue())
            }
        }
    }

}

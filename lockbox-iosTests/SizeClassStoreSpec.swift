/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxTest
import UIKit

@testable import Lockbox

class SizeClassStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    private var subject: SizeClassStore!
    private var dispatcher: FakeDispatcher!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var sidebarObserver: RxTest.TestableObserver<Bool>!

    override func spec() {
        describe("SizeClassStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.subject = SizeClassStore(dispatcher: self.dispatcher)
                self.sidebarObserver = self.scheduler.createObserver(Bool.self)

                self.subject.shouldDisplaySidebar
                    .bind(to: self.sidebarObserver)
                    .disposed(by: self.disposeBag)
            }

            describe("handles expanding screen") {
                beforeEach {
                    self.dispatcher.fakeRegistration.onNext(SizeClassAction.changed(traitCollection: UITraitCollection(horizontalSizeClass: .regular)))
                }

                it("updates observer") {
                    expect(self.sidebarObserver.events.count).to(equal(1))
                    expect(self.sidebarObserver.events.first!.value.element!).to(beTrue())
                }
            }

            describe("handles condensed screen") {
                beforeEach {
                    self.dispatcher.fakeRegistration.onNext(SizeClassAction.changed(traitCollection: UITraitCollection(horizontalSizeClass: .compact)))
                }

                it("updates observer") {
                    expect(self.sidebarObserver.events.count).to(equal(1))
                    expect(self.sidebarObserver.events.first!.value.element!).to(beFalse())
                }
            }

            describe("handles unspecified") {
                beforeEach {
                    self.dispatcher.fakeRegistration.onNext(SizeClassAction.changed(traitCollection: UITraitCollection(horizontalSizeClass: .unspecified)))
                }

                it("updates observer") {
                    expect(self.sidebarObserver.events.count).to(equal(1))
                    expect(self.sidebarObserver.events.first!.value.element!).to(beFalse())
                }
            }
        }
    }
}

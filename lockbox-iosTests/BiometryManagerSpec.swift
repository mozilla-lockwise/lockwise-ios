/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import LocalAuthentication
import RxSwift
import RxTest

@testable import Lockbox

@available(iOS 11.0, *)
var biometryTypeStub: LABiometryType!

class BiometryManagerSpec: QuickSpec {
    class FakeLAContext: LAContext {
        var evaluateReason: String?
        var evaluateReply: ((Bool, Error?) -> Void)?

        override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
            self.evaluateReason = localizedReason
            self.evaluateReply = reply
        }
    }

    private var context: FakeLAContext!
    private var scheduler = TestScheduler(initialClock: 0)
    private var disposeBag = DisposeBag()
    var subject: BiometryManager!

    override func spec() {
        describe("BiometryManager") {
            beforeEach {
                self.context = FakeLAContext()
                self.subject = BiometryManager(context: self.context)
            }

            describe("authenticateWithMessage") {
                let message = "tjacobson@yahoo.com"
                var voidObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    voidObserver = self.scheduler.createObserver(Void.self)
                }

                describe("when the app can evaluate owner authentication") {
                    beforeEach {
                        self.subject.authenticateWithMessage(message)
                                .asObservable()
                                .subscribe(voidObserver)
                                .disposed(by: self.disposeBag)
                    }

                    it("passes the message to the policy evaluation") {
                        expect(self.context.evaluateReason).to(equal(message))
                    }

                    describe("when the authentication succeeds") {
                        beforeEach {
                            self.context.evaluateReply!(true, nil)
                        }

                        it("pushes a void event to the observer") {
                            expect(voidObserver.events.first!.value.element).notTo(beNil())
                        }
                    }

                    describe("when the authentication fails") {
                        let error = NSError(domain: "localauthentication", code: -1)
                        beforeEach {
                            self.context.evaluateReply!(false, error)
                        }

                        it("pushes the error to the observer") {
                            expect(voidObserver.events.first!.value.error).to(matchError(error))
                        }
                    }
                }
            }
        }
    }
}

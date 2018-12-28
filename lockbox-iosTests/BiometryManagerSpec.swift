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

var biometryTypeStub: LABiometryType!

class BiometryManagerSpec: QuickSpec {
    class FakeLAContext: LAContext {
        var evaluateReason: String?
        var evaluateReply: ((Bool, Error?) -> Void)?
        var canEvaluatePolicyStub: Bool!

        override func evaluatePolicy(_ policy: LAPolicy, localizedReason: String, reply: @escaping (Bool, Error?) -> Void) {
            self.evaluateReason = localizedReason
            self.evaluateReply = reply
        }

        override func canEvaluatePolicy(_ policy: LAPolicy, error: NSErrorPointer) -> Bool {
            return self.canEvaluatePolicyStub
        }

        override var biometryType: LABiometryType {
            return biometryTypeStub
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

            describe("usesFaceId") {
                describe("when the app can evaluate deviceOwnerAuthenticationWithBiometrics") {
                    beforeEach {
                        self.context.canEvaluatePolicyStub = true
                    }

                    describe("when the biometry type is faceID") {
                        beforeEach {
                            biometryTypeStub = .faceID
                        }

                        it("returns true") {
                            expect(self.subject.usesFaceID).to(beTrue())
                        }
                    }

                    describe("when the biometry type is not faceID") {
                        beforeEach {
                            biometryTypeStub = .touchID
                        }

                        it("returns false") {
                            expect(self.subject.usesFaceID).to(beFalse())
                        }
                    }
                }

                describe("when the app cannot evaluate deviceOwnerAuthenticationWithBiometrics") {
                    beforeEach {
                        self.context.canEvaluatePolicyStub = false
                    }

                    it("returns false") {
                        expect(self.subject.usesFaceID).to(beFalse())
                    }
                }
            }

            describe("usesTouchId") {
                describe("when the app can evaluate deviceOwnerAuthenticationWithBiometrics") {
                    beforeEach {
                        self.context.canEvaluatePolicyStub = true
                    }

                    describe("when the biometry type is touchID") {
                        beforeEach {
                            biometryTypeStub = .touchID
                        }

                        it("returns true") {
                            expect(self.subject.usesTouchID).to(beTrue())
                        }
                    }

                    describe("when the biometry type is not touchID") {
                        beforeEach {
                            biometryTypeStub = .faceID
                        }

                        it("returns false") {
                            expect(self.subject.usesTouchID).to(beFalse())
                        }
                    }
                }

                describe("authenticateWithMessage") {
                    let message = "tjacobson@yahoo.com"
                    var voidObserver = self.scheduler.createObserver(Void.self)

                    beforeEach {
                        voidObserver = self.scheduler.createObserver(Void.self)
                    }

                    describe("when the app can evaluate owner authentication") {
                        beforeEach {
                            self.context.canEvaluatePolicyStub = true
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

                    describe("when the app cannot evaluate owner authentication") {
                        beforeEach {
                            beforeEach {
                                self.context.canEvaluatePolicyStub = false
                                self.subject.authenticateWithMessage(message)
                                        .asObservable()
                                        .subscribe(voidObserver)
                                        .disposed(by: self.disposeBag)
                            }

                            it("passes the error to the observer") {
                                expect(voidObserver.events.first!.value.error).to(matchError(LocalError.LAError))
                            }
                        }
                    }
                }

                describe("deviceAuthenticationAvailable") {
                    it("returns the value of canEvaluatePolicy") {
                        self.context.canEvaluatePolicyStub = true
                        expect(self.subject.deviceAuthenticationAvailable).to(beTrue())
                        self.context.canEvaluatePolicyStub = false
                        expect(self.subject.deviceAuthenticationAvailable).to(beFalse())
                    }
                }
            }
        }
    }
}

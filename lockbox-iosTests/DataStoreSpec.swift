/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift
import RxBlocking
import SwiftKeychainWrapper

@testable import Lockbox

class DataStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let fakeRegistration = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.fakeRegistration.asObservable()
        }
    }

    class FakeKeychainWrapper: KeychainWrapper {
        var saveArguments: [String: String] = [:]
        var saveSuccess: Bool!
        var retrieveResult: [String: String] = [:]

        override func set(_ value: String, forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> Bool {
//            self.saveArguments[key] = string
            return saveSuccess
        }

        override func string(forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil) -> String? {
            return retrieveResult[key]
        }

        init() { super.init(serviceName: "blah") }
    }

    private var scheduler: TestScheduler = TestScheduler(initialClock: 1)
    private var disposeBag = DisposeBag()

    private var dispatcher: FakeDispatcher!
    private var keychainWrapper: FakeKeychainWrapper!
    var subject: DataStore!

    override func spec() {
        describe("DataStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.keychainWrapper = FakeKeychainWrapper()
                self.subject = DataStore(
                        dispatcher: self.dispatcher,
                        keychainWrapper: self.keychainWrapper
                )
            }
        }
    }
}

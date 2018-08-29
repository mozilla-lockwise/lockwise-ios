/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import AuthenticationServices
import RxSwift
import RxCocoa

@testable import Lockbox

@available(iOS 12, *)
class CredentialProviderStoreSpec: QuickSpec {
    class FakeDispatcher: Dispatcher {
        let registerStub = PublishSubject<Action>()

        override var register: Observable<Action> {
            return self.registerStub.asObservable()
        }
    }

    class FakeDataStore: DataStore {
  
    }

    class FakeCredentialIdentityStore: CredentialIdentityStoreProtocol {
        var storeState: ASCredentialIdentityStoreState!

        var removeSuccess: Bool!
        var removeError: Error?

        var credentialIdentities: [ASPasswordCredentialIdentity]?
        var addSuccess: Bool!
        var addError: Error?

        func getState(_ completion: @escaping (ASCredentialIdentityStoreState) -> Void) {
            completion(self.storeState)
        }

        func removeAllCredentialIdentities(_ completion: ((Bool, Error?) -> Void)?) {
            completion!(removeSuccess, removeError)
        }

        func saveCredentialIdentities(_ credentialIdentities: [ASPasswordCredentialIdentity], completion: ((Bool, Error?) -> Void)?) {
            self.credentialIdentities = credentialIdentities
            completion!(addSuccess, addError)
        }
    }

    private var dispatcher: FakeDispatcher!
    private var dataStore: FakeDataStore!
    private var credentialIdentityStore: FakeCredentialIdentityStore!

    var subject: CredentialProviderStore!

    override func spec() {
        describe("CredentialProviderStore") {
            beforeEach {
                self.dispatcher = FakeDispatcher()
                self.dataStore = FakeDataStore()
                self.credentialIdentityStore = FakeCredentialIdentityStore()

                self.subject = CredentialProviderStore(
                    dispatcher: self.dispatcher,
                    dataStore: self.dataStore,
                    credentialStore: self.credentialIdentityStore)
            }

            describe("init") {
                
            }
        }
    }
}

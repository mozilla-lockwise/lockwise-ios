/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AuthenticationServices

@available(iOS 12, *)
protocol CredentialIdentityStoreProtocol {
    func getState(_ completion: @escaping (ASCredentialIdentityStoreState) -> Void)
    func removeAllCredentialIdentities(_ completion: ((Bool, Error?) -> Void)?)
    func saveCredentialIdentities(_ credentialIdentities: [ASPasswordCredentialIdentity], completion: ((Bool, Error?) -> Void)?)
}

@available(iOS 12, *)
extension ASCredentialIdentityStore: CredentialIdentityStoreProtocol { }

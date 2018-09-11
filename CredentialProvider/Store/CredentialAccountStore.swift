/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import FxAClient
import SwiftKeychainWrapper

class AccountStore: BaseAccountStore {
    static let shared = AccountStore()

    override func initialized() {
        if let accountJSON = self.storedAccountJSON {
            self.fxa = try? FirefoxAccount.fromJSON(state: accountJSON)
            self.populateAccountInformation()
        } else {
            self._oauthInfo.onNext(nil)
            self._profile.onNext(nil)
        }
    }
}

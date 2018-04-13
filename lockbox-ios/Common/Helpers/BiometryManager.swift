/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import LocalAuthentication
import RxSwift

enum LocalError: Error {
    case Unknown
}

class BiometryManager {
    private let context: LAContext

    var usesFaceID: Bool {
        let authContext = LAContext()
        var error: NSError?
        if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if #available(iOS 11.0, *) {
                return authContext.biometryType == .faceID
            }
        }
        return false
    }

    var usesTouchID: Bool {
        let authContext = LAContext()
        var error: NSError?
        return authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    init(context: LAContext = LAContext()) {
        self.context = context
    }

    func authenticateWithMessage(_ message: String) -> Single<Void> {
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            return Single.create { [weak self] observer in
                self?.context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: message) { success, error in
                    if success {
                        observer(.success(()))
                    } else if let err = error {
                        observer(.error(err))
                    }
                }

                return Disposables.create()
            }

        } else if let err = error {
            return Single.error(err)
        }

        return Single.error(LocalError.Unknown)
    }
}

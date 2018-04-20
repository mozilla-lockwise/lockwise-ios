/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import LocalAuthentication
import RxSwift

enum LocalError: Error {
    case LAError
}

class BiometryManager {
    private let context: LAContext

    lazy var usesBiometrics: Bool = self.usesTouchID || self.usesFaceID

    var usesFaceID: Bool {
        if #available(iOS 11.0, *) {
            return self.usesBiometric(.faceID)
        }

        return false
    }

    var usesTouchID: Bool {
        if #available(iOS 11.0, *) {
            return self.usesBiometric(.touchID)
        }

        return self.context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    init(context: LAContext = LAContext()) {
        self.context = context
    }

    func authenticateWithMessage(_ message: String) -> Single<Void> {
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil) {
            return self.authenticate(message: message, policy: .deviceOwnerAuthentication)
        }

        return Single.error(LocalError.LAError)
    }

    func authenticateWithBiometrics(message: String) -> Single<Void> {
        return self.authenticate(message: message, policy: .deviceOwnerAuthenticationWithBiometrics)
    }

    @available(iOS 11.0, *)
    private func usesBiometric(_ biometry: LABiometryType) -> Bool {
        if self.context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
            return self.context.biometryType == biometry
        }

        return false
    }

    private func authenticate(message: String, policy: LAPolicy) -> Single<Void> {
        return Single.create { [weak self] observer in
            self?.context.evaluatePolicy(policy, localizedReason: message) { success, error in
                if success {
                    observer(.success(()))
                } else if let err = error {
                    observer(.error(err))
                }
            }

            return Disposables.create()
        }
    }
}

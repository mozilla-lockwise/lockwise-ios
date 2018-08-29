/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxOptional
import CoreGraphics
import FxAClient

protocol BaseWelcomeViewProtocol: class, AlertControllerView { }

class BaseWelcomePresenter {
    internal weak var baseView: BaseWelcomeViewProtocol?

    internal let dispatcher: Dispatcher
    internal let accountStore: AccountStore
    internal let dataStore: DataStore
    internal let lifecycleStore: LifecycleStore
    internal let biometryManager: BiometryManager
    internal let disposeBag = DisposeBag()

    init(view: BaseWelcomeViewProtocol,
         dispatcher: Dispatcher = .shared,
         accountStore: AccountStore = AccountStore.shared,
         dataStore: DataStore = DataStore.shared,
         lifecycleStore: LifecycleStore = LifecycleStore.shared,
         biometryManager: BiometryManager = BiometryManager()) {
        self.baseView = view
        self.dispatcher = dispatcher
        self.accountStore = accountStore
        self.dataStore = dataStore
        self.lifecycleStore = lifecycleStore
        self.biometryManager = biometryManager
    }

    func onViewReady() {
        fatalError("not implemented!")
    }
}

extension BaseWelcomePresenter {
    internal func launchBiometrics(message: String) -> Single<Void> {
        if !self.biometryManager.deviceAuthenticationAvailable {
            return Single.just(())
        }

        return self.biometryManager.authenticateWithMessage(message)
            .catchError { _ in
                // ignore errors from local authentication
                return Observable.never().asSingle()
        }
    }
}

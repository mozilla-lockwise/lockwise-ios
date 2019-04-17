/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import Reachability

class NetworkStore {
    static let shared = NetworkStore()

    private var reachability: ReachabilityProtocol?

    private let _connectedToNetwork = BehaviorRelay<Bool>(value: false)

    // not using this Observable anywhere yet, but it will be handy to have
    // if we do any further work around offline mode
    public var connectedToNetwork: Observable<Bool> {
        return _connectedToNetwork.asObservable()
    }

    public var isConnectedToNetwork: Bool {
        return _connectedToNetwork.value
    }

    init(reachability: ReachabilityProtocol? = Reachability()) {
        self.reachability = reachability

        self.reachability?.whenReachable = { [weak self] reachable in
            self?._connectedToNetwork.accept(true)
        }

        self.reachability?.whenUnreachable = { [weak self] _ in
            self?._connectedToNetwork.accept(false)
        }
 
        if !isRunningTest {
            try? self.reachability?.startNotifier()
        }
    }
}

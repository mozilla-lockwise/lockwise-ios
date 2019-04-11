/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Network
import RxSwift
import RxCocoa

class NetworkHelper {
    static let shared = NetworkHelper()

    private let _connectedToNetwork = BehaviorRelay<Bool>(value: false)

    public var connectedToNetwork: Observable<Bool> {
        return _connectedToNetwork.asObservable()
    }

    public var isConnectedToNetwork: Bool {
        return _connectedToNetwork.value
    }

    init() {
        if #available(iOS 12.0, *) {
            let monitor = NWPathMonitor()
            
            let queue = DispatchQueue.global(qos: .background)
            
            monitor.pathUpdateHandler = { [weak self] path in
                switch path.status {
                case .satisfied:
                    self?._connectedToNetwork.accept(true)
                case .unsatisfied, .requiresConnection:
                    self?._connectedToNetwork.accept(false)
                }
            }
            
            monitor.start(queue: queue)
        } else {
            // Fallback on earlier versions
        }

    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxRelay
import Reachability

open class NetworkStore {
    static let shared = NetworkStore()

    private var reachability: ReachabilityProtocol?
    private let dispatcher: Dispatcher
    private let disposeBag = DisposeBag()

    private let _connectedToNetwork = BehaviorRelay<Bool>(value: false)

    // not using this Observable anywhere yet, but it will be handy to have
    // if we do any further work around offline mode
    open var connectedToNetwork: Observable<Bool> {
        return _connectedToNetwork.asObservable()
    }

    open var isConnectedToNetwork: Bool {
        return _connectedToNetwork.value
    }

    init(
        reachability: ReachabilityProtocol? = Reachability(),
        dispatcher: Dispatcher = .shared
        ) {
        self.reachability = reachability
        self.dispatcher = dispatcher
        let currentlyReachable = (reachability?.connection ?? Reachability.Connection.none) != .none

        self._connectedToNetwork.accept(currentlyReachable)

        self.reachability?.whenReachable = { [weak self] reachable in
            self?._connectedToNetwork.accept(true)
        }

        self.reachability?.whenUnreachable = { [weak self] _ in
            self?._connectedToNetwork.accept(false)
        }
 
        if !isRunningTest {
            ((try? self.reachability?.startNotifier()) as ()??)
        }

        dispatcher.register
                .filterByType(class: NetworkAction.self)
                .filter { $0 == NetworkAction.retry }
                .map { _ in (self.reachability?.connection ?? Reachability.Connection.none) != .none }
                .bind(to: self._connectedToNetwork)
                .disposed(by: self.disposeBag)
    }
}

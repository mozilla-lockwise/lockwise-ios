/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import FxAUtils
import RxSwift
import RxCocoa
import SwiftyJSON
import Account

protocol FxAViewProtocol: class {
    func loadRequest(_ urlRequest: URLRequest)
}

struct LockedSyncState {
    let locked: Bool
    let state: SyncState
}

class FxAPresenter {
    private weak var view: FxAViewProtocol?
    fileprivate let settingActionHandler: SettingActionHandler
    fileprivate let routeActionHandler: RouteActionHandler
    fileprivate let dataStoreActionHandler: DataStoreActionHandler
    fileprivate let dataStore: DataStore

    private var disposeBag = DisposeBag()

    public var onClose: AnyObserver<Void> {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(LoginRouteAction.welcome)
        }.asObserver()
    }

    init(view: FxAViewProtocol,
         settingActionHandler: SettingActionHandler = SettingActionHandler.shared,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         dataStoreActionHandler: DataStoreActionHandler = DataStoreActionHandler.shared,
         dataStore: DataStore = DataStore.shared
    ) {
        self.view = view
        self.settingActionHandler = settingActionHandler
        self.routeActionHandler = routeActionHandler
        self.dataStoreActionHandler = dataStoreActionHandler
        self.dataStore = dataStore
    }

    func onViewReady() {
        self.view?.loadRequest(URLRequest(url: ProductionFirefoxAccountConfiguration().signInURL))
    }
}

// Extensions and enums to support logging in via remote commmand.
extension FxAPresenter {
    // The user has signed in to a Firefox Account.  We're done!
    func onLogin(_ data: JSON) {
        self.dataStore.syncState
            .take(1)
            .subscribe(onNext: { [weak self] syncState in
                if syncState == .NotSyncable {
                    self?.dataStoreActionHandler.invoke(.initialize(blob: data))
                    self?.routeActionHandler.invoke(MainRouteAction.list)
                }
            }).disposed(by: disposeBag)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import RxSwift
import RxCocoa
import FxAClient

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

    var fxa: FirefoxAccount?

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
        do {
            let config = try FxAConfig.custom(content_base: "https://accounts.firefox.com")
            self.fxa = try FirefoxAccount(config: config, clientId: Constant.fxa.clientID)

            guard let url = try self.fxa?.beginOAuthFlow(
                    redirectURI: Constant.fxa.redirectURI,
                    scopes: [
                        "profile",
                        "https://identity.mozilla.com/apps/oldsync",
                        "https://identity.mozilla.com/apps/lockbox"],
                    wantsKeys: true) else { return }

            self.view?.loadRequest(URLRequest(url: url))
        } catch {
            print(error)
        }
    }

    func matchingRedirectURLReceived(_ components: URLComponents) {
        var dic = [String: String]()
        components.queryItems?.forEach {
            dic[$0.name] = $0.value
        }
        guard let code = dic["code"], let state = dic["state"] else { return }

        var oauthInfo: OAuthInfo?
        do {
            oauthInfo = try self.fxa?.completeOAuthFlow(code: code, state: state)
        } catch {
            print(error)
        }

        var profile: Profile?
        do {
            profile = try self.fxa?.getProfile()
            if profile != nil {
                UserInfoActionHandler.shared.invoke(UserInfoAction.profileInfo(info: profile))
            }
        } catch {
            print(error)
        }

        if let accessToken = oauthInfo?.accessToken,
           let keys = oauthInfo?.keys {
            print("access_token: " + accessToken)
            print("keysJWE: " + keys)
        }
    }
}

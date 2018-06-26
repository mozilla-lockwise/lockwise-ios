/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxCocoa
import RxSwift
import WebKit

protocol AccountSettingViewProtocol: class, AlertControllerView {
    func bind(avatarImage: Driver<Data>)
    func bind(displayName: Driver<String>)
}

class AccountSettingPresenter {
    weak var view: AccountSettingViewProtocol?
    let userInfoStore: UserInfoStore
    let routeActionHandler: RouteActionHandler
    let dataStoreActionHandler: DataStoreActionHandler
    let userInfoActionHandler: UserInfoActionHandler
    let webKitDataStore: WKWebsiteDataStore

    lazy private var unlinkAccountObserver: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.webKitDataStore.removeData(
                ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
                modifiedSince: Date.distantPast,
                completionHandler: { })
            target.dataStoreActionHandler.invoke(.reset)
            target.userInfoActionHandler.invoke(.clear)
        }.asObserver()
    }()

    lazy private(set) var onSettingsTap: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(SettingRouteAction.list)
        }.asObserver()
    }()

    lazy private(set) var unLinkAccountTapped: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.view?.displayAlertController(buttons: [
                AlertActionButtonConfiguration(title: Constant.string.cancel,
                                               tapObserver: nil,
                                               style: .cancel),
                AlertActionButtonConfiguration(title: Constant.string.unlink,
                        tapObserver: target.unlinkAccountObserver,
                        style: .destructive)],
                    title: Constant.string.confirmDialogTitle,
                    message: Constant.string.confirmDialogMessage,
                    style: .alert)
        }.asObserver()
    }()

    init(view: AccountSettingViewProtocol,
         userInfoStore: UserInfoStore = UserInfoStore.shared,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         dataStoreActionHandler: DataStoreActionHandler = DataStoreActionHandler.shared,
         userInfoActionHandler: UserInfoActionHandler = UserInfoActionHandler.shared,
         webKitDataStore: WKWebsiteDataStore = WKWebsiteDataStore.default()
    ) {
        self.view = view
        self.userInfoStore = userInfoStore
        self.routeActionHandler = routeActionHandler
        self.dataStoreActionHandler = dataStoreActionHandler
        self.userInfoActionHandler = userInfoActionHandler
        self.webKitDataStore = webKitDataStore
    }

    func onViewReady() {
        let profileInfoObservable = self.userInfoStore.profileInfo
                .filterNil()

        let displayNameDriver = profileInfoObservable
                .map {
                    $0.displayName ?? $0.email
                }
                .asDriver(onErrorJustReturn: "")

        self.view?.bind(displayName: displayNameDriver)

        let avatarImageDriver = profileInfoObservable
                .flatMap { info -> Observable<Data?> in
                    guard let avatarURL = info.avatar else {
                        return Observable.just(nil)
                    }

                    return Data.loadImageData(avatarURL)
                }
                .filterByType(class: Data?.self)
                .asDriver(onErrorJustReturn: nil)
                .filterNil()

        self.view?.bind(avatarImage: avatarImageDriver)

        self.userInfoActionHandler.invoke(.load)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import UIKit

class ExternalLinkStore {
    static let shared = ExternalLinkStore()

    private let disposeBag = DisposeBag()
    private let dispatcher: Dispatcher
    private let application: OpenUrlProtocol
    private let userDefaultStore: UserDefaultStore

    init(dispatcher: Dispatcher = Dispatcher.shared,
         application: OpenUrlProtocol = UIApplication.shared,
         userDefaultStore: UserDefaultStore = .shared) {
        self.dispatcher = dispatcher
        self.application = application
        self.userDefaultStore = userDefaultStore

        self.dispatcher.register
            .filterByType(class: ExternalLinkAction.self)
            .subscribe(onNext: { action in
                self.openUrl(string: action.baseURLString)
            }).disposed(by: self.disposeBag)
        self.dispatcher.register
            .filterByType(class: SettingLinkAction.self)
            .subscribe(onNext: { action in
                self.openSettings(action)
            }).disposed(by: self.disposeBag)
    }

    // MARK: - Private

    private func openUrl(string url: String) {
        self.userDefaultStore.preferredBrowser
            .take(1)
            .subscribe(onNext: { (latest: Setting.PreferredBrowser) in
                latest.openUrl(url: url, application: self.application)
            })
            .disposed(by: self.disposeBag)
    }

    private func openSettings(_ action: SettingLinkAction) {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString),
            self.application.canOpenURL(settingsURL) {
            self.application.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
}

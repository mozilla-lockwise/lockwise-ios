/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import UIKit

protocol LinkAction: Action {}

struct ExternalLinkAction: LinkAction {
    let baseURLString: String
}

enum SettingLinkAction: LinkAction {
    case touchIDPasscode

    func toString() -> String {
        switch self {
        case .touchIDPasscode: return "App-Prefs:root=TOUCHID_PASSCODE"
        }
    }
}

extension ExternalLinkAction: Equatable {
    static func ==(lhs: ExternalLinkAction, rhs: ExternalLinkAction) -> Bool {
        return lhs.baseURLString == rhs.baseURLString
    }
}

class LinkActionHandler: ActionHandler {
    static let shared = LinkActionHandler()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let application: OpenUrlProtocol
    private let userDefaults: UserDefaults

    init(dispatcher: Dispatcher = Dispatcher.shared,
         application: OpenUrlProtocol = UIApplication.shared,
         userDefaults: UserDefaults = UserDefaults.standard) {
        self.dispatcher = dispatcher
        self.application = application
        self.userDefaults = userDefaults
    }

    func invoke(_ action: LinkAction) {
        if let externalLink = action as? ExternalLinkAction {
            self.openUrl(string: externalLink.baseURLString)
        } else if let settingLink = action as? SettingLinkAction {
            self.openSettings(settingLink)
        }
    }

    private func openUrl(string url: String) {
        self.userDefaults.onPreferredBrowser
            .take(1)
            .subscribe(onNext: { (latest: Setting.PreferredBrowser) in
                latest.openUrl(url: url, application: self.application)
            })
            .disposed(by: self.disposeBag)
    }

    private func openSettings(_ action: SettingLinkAction) {
        if let settingsURL = URL(string: action.toString()),
           self.application.canOpenURL(settingsURL) {
            self.application.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
}

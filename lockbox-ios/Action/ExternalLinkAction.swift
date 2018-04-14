/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import UIKit

struct ExternalLinkAction: Action {
    let url: String
}

extension ExternalLinkAction: Equatable {
    static func ==(lhs: ExternalLinkAction, rhs: ExternalLinkAction) -> Bool {
        return lhs.url == rhs.url
    }
}

class ExternalLinkActionHandler: ActionHandler {
    static let shared = ExternalLinkActionHandler()
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

    func invoke(_ action: ExternalLinkAction) {
        self.openUrl(string: action.url, application: self.application)
    }

    private func openUrl(string url: String, application: OpenUrlProtocol = UIApplication.shared) {
        self.userDefaults.rx.observe(String.self, SettingKey.preferredBrowser.rawValue)
            .take(1)
            .filterNil()
            .map { value -> PreferredBrowserSetting in
                guard let setting = PreferredBrowserSetting(rawValue: value)
                    else { return Constant.setting.defaultPreferredBrowser }
                return setting
            }
            .subscribe(onNext: { (latest: PreferredBrowserSetting) in
                latest.openUrl(url: url, application: application)
            })
            .disposed(by: self.disposeBag)
    }
}

enum PreferredBrowserSetting: String {
    case Chrome
    case Firefox
    case Focus
    case Safari

    func getPreferredBrowserDeeplink(url: String) -> URL? {
        guard let encodedString = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return nil }

        switch self {
        case .Safari:
            return URL(string: url)
        case .Firefox:
            return URL(string: "firefox://open-url?url=\(encodedString)")
        case .Focus:
            return URL(string: "firefox-focus://open-url?url=\(encodedString)")
        case .Chrome:
            return URL(string: "googlechrome://\(url)")
        }
    }

    func canOpenBrowser(application: OpenUrlProtocol = UIApplication.shared) -> Bool {
        if let url = getPreferredBrowserDeeplink(url: "https://mozilla.org") {
            return application.canOpenURL(url)
        }

        return false
    }

    func openUrl(url: String,
                 application: OpenUrlProtocol = UIApplication.shared,
                 completion: ((Bool) -> Swift.Void)? = nil) {
        if let urlToOpen = getPreferredBrowserDeeplink(url: url) {
            application.open(urlToOpen, options: [:], completionHandler: completion)
        }
    }
}

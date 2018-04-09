/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import UIKit

struct ExternalLinkAction: Action {
    let url: String
}

class ExternalLinkActionHandler: ActionHandler {
    static let shared = ExternalLinkActionHandler()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let application: UIApplication
    private let userDefaults: UserDefaults

    init(dispatcher: Dispatcher = Dispatcher.shared,
         application: UIApplication = UIApplication.shared,
         userDefaults: UserDefaults = UserDefaults.standard) {
        self.dispatcher = dispatcher
        self.application = application
        self.userDefaults = userDefaults
    }

    func invoke(_ action: ExternalLinkAction) {
        self.openUrl(string: action.url)
    }

    private func openUrl(string url: String) {
        self.userDefaults.rx.observe(String.self, SettingKey.preferredBrowser.rawValue)
            .take(1)
            .map { value -> PreferredBrowserSetting in
                guard let value = value,
                    let setting = PreferredBrowserSetting(rawValue: value)
                    else { return PreferredBrowserSetting.defaultValue }
                return setting
            }
            .subscribe(onNext: { (latest: PreferredBrowserSetting) in
                latest.openUrl(url: url)
            })
            .disposed(by: self.disposeBag)
    }
}

enum PreferredBrowserSetting: String {
    case Chrome
    case Firefox
    case Focus
    case Safari

    static var defaultValue: PreferredBrowserSetting {
        return PreferredBrowserSetting.Safari
    }

    func canOpenBrowser(application: UIApplication = UIApplication.shared) -> Bool {
        var scheme: String?
        switch self {
        case .Safari:
            return true
        case .Firefox:
            scheme = "firefox://open-url?url=http://mozilla.org"
        case .Focus:
            scheme = "firefox-focus://open-url?url=http://mozilla.org"
        case .Chrome:
            scheme = "googlechrome://"
        }

        if let scheme = scheme,
            let url = URL(string: scheme) {
            return application.canOpenURL(url)
        }

        return false
    }

    func openUrl(url: String, application: UIApplication = UIApplication.shared) {
        var urlToOpen: URL?
        guard let encodedString = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else { return }

        switch self {
        case .Safari:
            urlToOpen = URL(string: "http://\(url)")
        case .Firefox:
            urlToOpen = URL(string: "firefox://open-url?url=http://\(encodedString)")
        case .Focus:
            urlToOpen = URL(string: "firefox-focus://open-url?url=http://\(encodedString)")
        case .Chrome:
            urlToOpen = URL(string: "googlechrome://\(url)")
        }

        if let urlToOpen = urlToOpen {
            application.open(urlToOpen, options: [:], completionHandler: nil)
        }
    }
}

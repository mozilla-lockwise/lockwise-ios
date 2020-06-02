/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

protocol PreferredBrowserSettingViewProtocol: class {
    func bind(items: Driver<[PreferredBrowserSettingSectionModel]>)
}

class PreferredBrowserSettingPresenter {
    private weak var view: PreferredBrowserSettingViewProtocol?
    private let dispatcher: Dispatcher
    private let userDefaultStore: UserDefaultStore
    private let disposeBag = DisposeBag()

    lazy var initialSettings = [
        CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserFirefox,
                                          valueWhenChecked: Setting.PreferredBrowser.Firefox),
        CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserChrome,
                                          valueWhenChecked: Setting.PreferredBrowser.Chrome),
        CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserSafari,
                                          valueWhenChecked: Setting.PreferredBrowser.Safari)
    ]

    lazy private(set) var itemSelectedObserver: AnyObserver<Setting.PreferredBrowser?> = {
        return Binder(self) { target, newPreferredBrowserValue in
            guard let newPreferredBrowserValue = newPreferredBrowserValue else {
                return
            }

            target.dispatcher.dispatch(action: SettingAction.preferredBrowser(browser: newPreferredBrowserValue))
        }.asObserver()
    }()

    init(view: PreferredBrowserSettingViewProtocol,
         dispatcher: Dispatcher = .shared,
         userDefaultStore: UserDefaultStore = .shared) {
        self.view = view
        self.dispatcher = dispatcher
        self.userDefaultStore = userDefaultStore
    }

    func onViewReady() {
        if let browser = getInstalledFocusBrowser() {
            self.initialSettings.insert(browser, at: 1)
        }

        let driver = self.userDefaultStore.preferredBrowser
            .map { setting -> [CheckmarkSettingCellConfiguration] in
                return self.initialSettings.map({ (cellConfiguration) -> CheckmarkSettingCellConfiguration in
                    cellConfiguration.isChecked =
                        (cellConfiguration.valueWhenChecked as? Setting.PreferredBrowser == setting)
                        && ((cellConfiguration.valueWhenChecked as? Setting.PreferredBrowser)?.canOpenBrowser() ?? false)
                    cellConfiguration.enabled =
                        (cellConfiguration.valueWhenChecked as? Setting.PreferredBrowser)?.canOpenBrowser() ?? false
                    return cellConfiguration
                })
            }
            .map { (cellConfigurations) -> [PreferredBrowserSettingSectionModel] in
                return [PreferredBrowserSettingSectionModel(model: 0, items: cellConfigurations)]
            }
            .asDriver(onErrorJustReturn: [])

        view?.bind(items: driver)
    }

    lazy private(set) var onSettingsTap: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.dispatcher.dispatch(action: SettingRouteAction.list)
            }.asObserver()
    }()

    private func getInstalledFocusBrowser() -> CheckmarkSettingCellConfiguration? {
        if Setting.PreferredBrowser.Focus.canOpenBrowser() {
            return CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserFocus,
                                                     valueWhenChecked: Setting.PreferredBrowser.Focus)
        } else if Setting.PreferredBrowser.Klar.canOpenBrowser() {
            return CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserKlar,
                                                     valueWhenChecked: Setting.PreferredBrowser.Klar)
        }

        return nil
    }
}

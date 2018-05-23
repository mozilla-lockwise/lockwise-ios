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
    private var userDefaults: UserDefaults
    private var routeActionHandler: RouteActionHandler
    private var settingActionHandler: SettingActionHandler
    private var disposeBag = DisposeBag()

    lazy var initialSettings = [
        CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserFirefox,
                                          valueWhenChecked: PreferredBrowserSetting.Firefox),
        CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserFocus,
                                          valueWhenChecked: PreferredBrowserSetting.Focus),
        CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserChrome,
                                          valueWhenChecked: PreferredBrowserSetting.Chrome),
        CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserSafari,
                                          valueWhenChecked: PreferredBrowserSetting.Safari)
    ]

    lazy private(set) var itemSelectedObserver: AnyObserver<PreferredBrowserSetting?> = {
        return Binder(self) { target, newPreferredBrowserValue in
            guard let newPreferredBrowserValue = newPreferredBrowserValue else {
                return
            }

            target.settingActionHandler.invoke(.preferredBrowser(browser: newPreferredBrowserValue))
        }.asObserver()
    }()

    init(view: PreferredBrowserSettingViewProtocol,
         userDefaults: UserDefaults = UserDefaults.standard,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         settingActionHandler: SettingActionHandler = SettingActionHandler.shared) {
        self.view = view
        self.userDefaults = userDefaults
        self.routeActionHandler = routeActionHandler
        self.settingActionHandler = settingActionHandler
    }

    func onViewReady() {
        let driver = self.userDefaults.rx.observe(String.self, SettingKey.preferredBrowser.rawValue)
            .filterNil()
            .map { value -> PreferredBrowserSetting? in
                return PreferredBrowserSetting(rawValue: value)
            }
            .filterNil()
            .map { setting -> [CheckmarkSettingCellConfiguration] in
                return self.initialSettings.map({ (cellConfiguration) -> CheckmarkSettingCellConfiguration in
                    cellConfiguration.isChecked =
                        cellConfiguration.valueWhenChecked as? PreferredBrowserSetting == setting
                    cellConfiguration.enabled =
                        (cellConfiguration.valueWhenChecked as? PreferredBrowserSetting)?.canOpenBrowser() ?? false
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
            target.routeActionHandler.invoke(SettingRouteAction.list)
            }.asObserver()
    }()
}

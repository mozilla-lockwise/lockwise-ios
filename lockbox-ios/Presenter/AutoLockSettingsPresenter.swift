/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

protocol AutoLockSettingViewProtocol {
    func bind(items: Driver<[AutoLockSettingSectionModel]>)
}

class AutoLockSettingPresenter {
    private var view: AutoLockSettingViewProtocol
    private var userDefaults: UserDefaults
    private var routeActionHandler: RouteActionHandler
    private var settingActionHandler: SettingActionHandler
    private var disposeBag = DisposeBag()

    lazy var initialSettings = [
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockOnAppExit, isChecked: false,
                                          valueWhenChecked: AutoLockSetting.OnAppExit),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockOneMinute, isChecked: false,
                                          valueWhenChecked: AutoLockSetting.OneMinute),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockFiveMinutes, isChecked: false,
                                          valueWhenChecked: AutoLockSetting.FiveMinutes),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockOneHour, isChecked: false,
                                          valueWhenChecked: AutoLockSetting.OneHour),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockTwelveHours, isChecked: false,
                                          valueWhenChecked: AutoLockSetting.TwelveHours),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockTwentyFourHours, isChecked: false,
                                          valueWhenChecked: AutoLockSetting.TwentyFourHours),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockNever, isChecked: false,
                                          valueWhenChecked: AutoLockSetting.Never)
    ]

    lazy private(set) var itemSelectedObserver: AnyObserver<AutoLockSetting?> = {
        return Binder(self) { target, newAutoLockValue in
            if let newAutoLockValue = newAutoLockValue {
                target.settingActionHandler.invoke(.autoLockTime(timeout: newAutoLockValue))
            }
        }.asObserver()
    }()

    init(view: AutoLockSettingViewProtocol,
         userDefaults: UserDefaults = UserDefaults.standard,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         settingActionHandler: SettingActionHandler = SettingActionHandler.shared) {
        self.view = view
        self.userDefaults = userDefaults
        self.routeActionHandler = routeActionHandler
        self.settingActionHandler = settingActionHandler
    }

    func onViewReady() {
        let driver = self.userDefaults.onAutoLockTime
                .map { setting -> [CheckmarkSettingCellConfiguration] in
                    return self.initialSettings.map { (cellConfiguration) -> CheckmarkSettingCellConfiguration in
                        cellConfiguration.isChecked =
                                (cellConfiguration.valueWhenChecked as? AutoLockSetting) == setting ? true : false
                        return cellConfiguration
                    }
                }
                .map { cellConfigurations -> [AutoLockSettingSectionModel] in
                    return [AnimatableSectionModel(model: 0, items: cellConfigurations)]
                }
                .asDriver(onErrorJustReturn: [])

        view.bind(items: driver)
    }

    lazy private(set) var onSettingsTap: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(SettingRouteAction.list)
            }.asObserver()
    }()
}

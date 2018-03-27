/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

protocol AutoLockSettingsViewProtocol {
    func bind(items: Driver<[AutoLockSettingSectionModel]>)
}

class AutoLockSettingsPresenter {
    private var view: AutoLockSettingsViewProtocol
    private var userInfoStore: UserInfoStore
    private var routeActionHandler: RouteActionHandler
    private var userInfoActionHandler: UserInfoActionHandler
    private var disposeBag = DisposeBag()

    var initialSettings = [
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
            guard let newAutoLockValue = newAutoLockValue else {
                return
            }

            target.userInfoActionHandler.invoke(.autoLock(value: newAutoLockValue))
            }.asObserver()
    }()

    init(view: AutoLockSettingsViewProtocol,
         userInfoStore: UserInfoStore = UserInfoStore.shared,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         userInfoActionHandler: UserInfoActionHandler = UserInfoActionHandler.shared) {
        self.view = view
        self.userInfoStore = userInfoStore
        self.routeActionHandler = routeActionHandler
        self.userInfoActionHandler = userInfoActionHandler
    }

    func onViewReady() {
        let driver = self.userInfoStore.autoLock.map({ (setting) -> [CheckmarkSettingCellConfiguration] in
            return self.initialSettings.map { (cellConfiguration) -> CheckmarkSettingCellConfiguration in
                cellConfiguration.isChecked = (cellConfiguration.valueWhenChecked as? AutoLockSetting) == setting ? true : false
                return cellConfiguration
            }
        }).map { (cellConfigurations) -> [AutoLockSettingSectionModel] in
            return [AnimatableSectionModel(model: 0, items: cellConfigurations)]
        }.asDriver(onErrorJustReturn: [])

        view.bind(items: driver)
    }
}

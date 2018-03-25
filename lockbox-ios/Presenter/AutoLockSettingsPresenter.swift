/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources

class AutoLockSettingsPresenter {
    private var view: AutoLockSettingsProtocol
    private var userInfoStore: UserInfoStore
    private var routeActionHandler: RouteActionHandler
    private var userInfoActionHandler: UserInfoActionHandler
    private var disposeBag = DisposeBag()

    var settings = Variable([AnimatableSectionModel(model: 0, items: [
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockOnAppExit, isChecked: false,
                                          value: AutoLockSetting.OnAppExit),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockOneMinute, isChecked: false,
                                          value: AutoLockSetting.OneMinute),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockFiveMinutes, isChecked: false,
                                          value: AutoLockSetting.FiveMinutes),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockOneHour, isChecked: false,
                                          value: AutoLockSetting.OneHour),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockTwelveHours, isChecked: false,
                                          value: AutoLockSetting.TwelveHours),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockTwentyFourHours, isChecked: false,
                                          value: AutoLockSetting.TwentyFourHours),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockNever, isChecked: false,
                                          value: AutoLockSetting.Never)
    ])])

    init(view: AutoLockSettingsProtocol,
         userInfoStore: UserInfoStore = UserInfoStore.shared,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         userInfoActionHandler: UserInfoActionHandler = UserInfoActionHandler.shared) {
        self.view = view
        self.userInfoStore = userInfoStore
        self.routeActionHandler = routeActionHandler
        self.userInfoActionHandler = userInfoActionHandler

        self.userInfoStore.autoLock.subscribe(onNext: { setting in
            self.updateAutoLockValue(setting)
        }).disposed(by: disposeBag)
    }

    func onViewReady() {
        let driver  = settings.asDriver()
        view.bind(items: driver)
    }

    func itemSelected(_ newValue: AutoLockSetting) {
        userInfoActionHandler.invoke(.autoLock(value: newValue))
    }

    private func updateAutoLockValue(_ setting: AutoLockSetting?) {
        let sectionModel = settings.value[0]
        let newItems = sectionModel.items.map { (cellConfiguration) -> CheckmarkSettingCellConfiguration in
            cellConfiguration.isChecked = (cellConfiguration.value as? AutoLockSetting) == setting ? true : false
            return cellConfiguration
        }

        settings.value = [AnimatableSectionModel(model: 0, items: newItems)]
    }
}

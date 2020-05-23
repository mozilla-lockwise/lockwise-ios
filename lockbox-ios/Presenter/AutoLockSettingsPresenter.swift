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
    private let dispatcher: Dispatcher
    private var settingStore: SettingStore
    private var disposeBag = DisposeBag()

    lazy var initialSettings = [
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockOneMinute, isChecked: false,
                                          valueWhenChecked: Setting.AutoLock.OneMinute),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockFiveMinutes, isChecked: false,
                                          valueWhenChecked: Setting.AutoLock.FiveMinutes),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockFifteenMinutes, isChecked: false,
                                          valueWhenChecked: Setting.AutoLock.FifteenMinutes),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockThirtyMinutes, isChecked: false,
                                          valueWhenChecked: Setting.AutoLock.ThirtyMinutes),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockOneHour, isChecked: false,
                                          valueWhenChecked: Setting.AutoLock.OneHour),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockTwelveHours, isChecked: false,
                                          valueWhenChecked: Setting.AutoLock.TwelveHours),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockTwentyFourHours, isChecked: false,
                                          valueWhenChecked: Setting.AutoLock.TwentyFourHours),
        CheckmarkSettingCellConfiguration(text: Constant.string.autoLockNever, isChecked: false,
                                          valueWhenChecked: Setting.AutoLock.Never)
    ]

    lazy private(set) var itemSelectedObserver: AnyObserver<Setting.AutoLock?> = {
        return Binder(self) { target, newAutoLockValue in
            if let newAutoLockValue = newAutoLockValue {
                target.dispatcher.dispatch(action: SettingAction.autoLockTime(timeout: newAutoLockValue))
            }
        }.asObserver()
    }()

    init(view: AutoLockSettingViewProtocol,
         dispatcher: Dispatcher = .shared,
         settingStore: SettingStore = .shared) {
        self.view = view
        self.dispatcher = dispatcher
        self.settingStore = settingStore
    }

    func onViewReady() {
        let driver = self.settingStore.autoLockTime
                .map { setting -> [CheckmarkSettingCellConfiguration] in
                    return self.initialSettings.map { (cellConfiguration) -> CheckmarkSettingCellConfiguration in
                        cellConfiguration.isChecked =
                                (cellConfiguration.valueWhenChecked as? Setting.AutoLock) == setting ? true : false
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
            target.dispatcher.dispatch(action: SettingRouteAction.list)
            }.asObserver()
    }()
}

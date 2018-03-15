/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LocalAuthentication

class SettingsPresenter {
    private var view: SettingsProtocol
    private var userInfoStore: UserInfoStore
    private var routeActionHandler: RouteActionHandler
    private var userInfoActionHandler: UserInfoActionHandler
    
    lazy private(set) var onDone: AnyObserver<Void> = {
        return Binder(self) { target, _ in
            target.routeActionHandler.invoke(MainRouteAction.dismissSettings)
            }.asObserver()
    }()
    
    var settings = Variable([SettingSectionModel(model: 0, items: [
        SettingCellConfiguration(text: Constant.string.settingsProvideFeedback, routeAction: SettingsRouteAction.provideFeedback),
        SettingCellConfiguration(text: Constant.string.settingsFaq, routeAction: SettingsRouteAction.faq),
        SettingCellConfiguration(text: Constant.string.settingsEnableInBrowser, routeAction: SettingsRouteAction.enableInBrowser),
        ]),
        SettingSectionModel(model: 1, items: [
            SettingCellConfiguration(text: Constant.string.settingsAccount, routeAction: SettingsRouteAction.account),
            SettingCellConfiguration(text: Constant.string.settingsAutoLock, routeAction: SettingsRouteAction.autoLock),
        ])
    ])

    let touchIdSetting = SwitchSettingCellConfiguration(text: Constant.string.settingsTouchId, routeAction: nil)
    let faceIdSetting = SwitchSettingCellConfiguration(text: Constant.string.settingsFaceId, routeAction: nil)
    
    private var usesFaceId: Bool {
        get {
            let authContext = LAContext()
            var error: NSError?
            if authContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                if #available(iOS 11.0, *) {
                    return authContext.biometryType == .faceID 
                }
            }
            return false
        }
    }
    
    init(view: SettingsProtocol,
         userInfoStore: UserInfoStore = UserInfoStore.shared,
         routeActionHandler: RouteActionHandler = RouteActionHandler.shared,
         userInfoActionHandler: UserInfoActionHandler = UserInfoActionHandler.shared) {
        self.view = view
        self.userInfoStore = userInfoStore
        self.routeActionHandler = routeActionHandler
        self.userInfoActionHandler = userInfoActionHandler
        
        let biometricSetting = usesFaceId ? faceIdSetting : touchIdSetting
        settings.value[1].items.insert(biometricSetting, at: settings.value[1].items.endIndex-1)
        
        userInfoStore.biometricLoginEnabled.subscribe(onNext: { enabled in
            biometricSetting.isOn = enabled ?? false
        })
    }
    
    func dismiss() {
        routeActionHandler.invoke(MainRouteAction.dismissSettings)
    }
    
    func switchChanged(row: Int, isOn: Bool) {
        userInfoActionHandler.invoke(.biometricLogin(enabled: isOn))
    }
    
    func onViewReady() {
        let driver  = settings.asDriver()
        view.bind(items: driver)
    }
}

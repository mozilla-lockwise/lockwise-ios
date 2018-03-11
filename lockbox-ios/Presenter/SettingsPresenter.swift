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
    
    var settings = [
        Setting(text: NSLocalizedString("settings.provideFeedback", value: "Provide Feedback", comment: "Provide feedback option in settings"), routeAction: SettingsRouteAction.provideFeedback),
        Setting(text: NSLocalizedString("settings.faq", value: "FAQ", comment: "FAQ option in settings"), routeAction: SettingsRouteAction.faq),
        Setting(text: NSLocalizedString("settings.enableInBrowser", value: "Enable In Browser", comment: "Enable In Browser option in settings"), routeAction: SettingsRouteAction.enableInBrowser),
        Setting(text: NSLocalizedString("settings.account", value: "Account", comment: "Account option in settings"), routeAction: SettingsRouteAction.account),
        Setting(text: NSLocalizedString("settings.autoLock", value: "Auto Lock", comment: "Auto Lock option in settings"), routeAction: SettingsRouteAction.autoLock),
    ]
    
    let touchIdSetting = SwitchSetting(text: NSLocalizedString("settings.touchId", value: "Touch ID", comment: "Touch ID option in settings"), routeAction: nil)
    let faceIdSetting = SwitchSetting(text: NSLocalizedString("settings.faceId", value: "Face ID", comment: "Face ID option in settings"), routeAction: nil)
    
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
        userInfoStore.biometricLoginEnabled.subscribe(onNext: { enabled in
            biometricSetting.isOn = enabled ?? false
        })
        
        settings.insert(biometricSetting, at: settings.endIndex-1)
    }
    
    func dismiss() {
        routeActionHandler.invoke(MainRouteAction.dismissSettings)
    }
    
    func switchChanged(row: Int, isOn: Bool) {
        userInfoActionHandler.invoke(.biometricLogin(enabled: isOn))
    }
    
    func onViewReady() {
        view.setItems(items: settings)
    }
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import FxAUtils
import UIKit
import Telemetry

let PostFirstRunKey = "firstrun"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, willFinishLaunchingWithOptions
                     launchOptions: [UIApplicationLaunchOptionsKey: Any]? = nil) -> Bool {
        _ = DataStore.shared
        _ = AutoLockStore.shared
        return true
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)

        self.window?.rootViewController = RootView()
        self.window?.makeKeyAndVisible()

        // This key will not be set on the first run of the application, only on subsequent runs.
        if UserDefaults.standard.string(forKey: PostFirstRunKey) == nil {
            SettingActionHandler.shared.invoke(.reset)
            AccountActionHandler.shared.invoke(.clear)
            DataStoreActionHandler.shared.invoke(.reset)
            UserDefaults.standard.set(false, forKey: PostFirstRunKey)
        }

        let navBarImage = UIImage.createGradientImage(
                frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height),
                colors: [Constant.color.lockBoxBlue, Constant.color.lockBoxTeal],
                locations: [0.15, 0]
        )
        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().barTintColor = UIColor(patternImage: navBarImage!)
            UINavigationBar.appearance().isTranslucent = true
            UINavigationBar.appearance().prefersLargeTitles = true
            UINavigationBar.appearance().largeTitleTextAttributes = [
                NSAttributedStringKey.foregroundColor: UIColor.white
            ]
        } else {
            UINavigationBar.appearance().setBackgroundImage(navBarImage, for: .default)
            UINavigationBar.appearance().isTranslucent = false
        }

        UITextField.appearance().tintColor = .black

        ApplicationLifecycleActionHandler.shared.invoke(LifecycleAction.startup)
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        ApplicationLifecycleActionHandler.shared.invoke(LifecycleAction.background)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        ApplicationLifecycleActionHandler.shared.invoke(LifecycleAction.foreground)
    }
}

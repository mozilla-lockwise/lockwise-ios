/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import FxAUtils
import UIKit
import Telemetry
import AdjustSdk
import SwiftKeychainWrapper

let PostFirstRunKey = "firstrun"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, willFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _ = AccountStore.shared
        _ = DataStore.shared
        _ = AutoLockStore.shared
        _ = ExternalLinkStore.shared
        return true
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)

        self.window?.rootViewController = RootView()
        self.window?.makeKeyAndVisible()

        // This key will not be set on the first run of the application, only on subsequent runs.
        let firstRun = UserDefaults.standard.string(forKey: PostFirstRunKey) == nil
        if firstRun {
            Dispatcher.shared.dispatch(action: AccountAction.clear)
            Dispatcher.shared.dispatch(action: DataStoreAction.reset)
            UserDefaults.standard.set(false, forKey: PostFirstRunKey)
        }

        if !firstRun {
            self.checkForUpgrades()
        }
        UserDefaults.standard.set(Constant.app.appVersionCode, forKey: LocalUserDefaultKey.appVersionCode.rawValue)

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
                NSAttributedString.Key.foregroundColor: UIColor.white
            ]
        } else {
            UINavigationBar.appearance().setBackgroundImage(navBarImage, for: .default)
            UINavigationBar.appearance().isTranslucent = false
        }

        UITextField.appearance().tintColor = .black

        setupAdjust()

        Dispatcher.shared.dispatch(action: LifecycleAction.startup)

        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Dispatcher.shared.dispatch(action: LifecycleAction.background)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Dispatcher.shared.dispatch(action: LifecycleAction.foreground)
    }

    private func setupAdjust() {
#if DEBUG
        let config = ADJConfig(appToken: Constant.app.adjustAppToken, environment: ADJEnvironmentSandbox)
        Adjust.appDidLaunch(config)
#else
        let config = ADJConfig(appToken: Constant.app.adjustAppToken, environment: ADJEnvironmentProduction)
        Adjust.appDidLaunch(config)
#endif
    }
}

extension AppDelegate {
    func checkForUpgrades() {
        let current = Constant.app.appVersionCode
        let previous = UserDefaults.standard.integer(forKey: LocalUserDefaultKey.appVersionCode.rawValue)

        if previous < current {
            // At the moment, this can be quite simple, since we don't have many migrations,
            // and we don't have many versions.
            // We may want to consider another lifecycle event (.upgradeComplete) to upgrade in stages
            // e.g. between version 1 to 3 may need an asynchronous upgrade event to go from 1 to 2, then from 2 to 3.
            Dispatcher.shared.dispatch(action: LifecycleAction.upgrade(from: previous, to: current))
        }
    }
}

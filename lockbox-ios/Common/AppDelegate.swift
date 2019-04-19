/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Telemetry
import SwiftKeychainWrapper

let PostFirstRunKey = "firstrun"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, willFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        _ = AccountStore.shared
        _ = DataStore.shared
        _ = ExternalLinkStore.shared
        _ = UserDefaultStore.shared
        if #available(iOS 12, *) {
            _ = CredentialProviderStore.shared
        }
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

        AppearanceHelper.shared.setupAppearance()

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

    func applicationWillTerminate(_ application: UIApplication) {
        Dispatcher.shared.dispatch(action: LifecycleAction.shutdown)
    }

    private func setupAdjust() {
        _ = AdjustManager.shared
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

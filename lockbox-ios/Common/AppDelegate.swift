/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Telemetry

let PostFirstRunKey = "firstrun"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)

        self.window?.rootViewController = RootView()
        self.window?.makeKeyAndVisible()

        // This key will not be set on the first run of the application, only on subsequent runs.
        if UserDefaults.standard.string(forKey: PostFirstRunKey) == nil {
            SettingActionHandler.shared.invoke(.reset)
            UserInfoActionHandler.shared.invoke(.clear)
            UserDefaults.standard.set(false, forKey: PostFirstRunKey)
        } else {
            UserInfoActionHandler.shared.invoke(.load)
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

        setupTelemetry()
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        Telemetry.default.recordEvent(
                category: TelemetryEventCategory.action,
                method: TelemetryEventMethod.background,
                object: TelemetryEventObject.app
        )
        Telemetry.default.recordSessionEnd()

        // Add the CorePing and FocusEventPing to the queue and schedule them for upload in the
        // background at iOS's discretion (usually happens immediately).
        Telemetry.default.queue(pingType: CorePingBuilder.PingType)
        Telemetry.default.queue(pingType: FocusEventPingBuilder.PingType)
        Telemetry.default.scheduleUpload(pingType: CorePingBuilder.PingType)
        Telemetry.default.scheduleUpload(pingType: FocusEventPingBuilder.PingType)
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Telemetry.default.recordEvent(
                category: TelemetryEventCategory.action,
                method: TelemetryEventMethod.foreground,
                object: TelemetryEventObject.app
        )
    }

    private func setupTelemetry() {
        let telemetryConfig = Telemetry.default.configuration
        telemetryConfig.appName = "Lockbox"
        telemetryConfig.userDefaultsSuiteName = AppInfo.sharedContainerIdentifier
        telemetryConfig.appVersion = AppInfo.shortVersion

#if DEBUG
        telemetryConfig.isCollectionEnabled = false
        telemetryConfig.isUploadEnabled = false
        telemetryConfig.updateChannel = "debug"
#else
        telemetryConfig.isCollectionEnabled = true
        telemetryConfig.isUploadEnabled = true
        telemetryConfig.updateChannel = "release"
#endif

        Telemetry.default.add(pingBuilderType: CorePingBuilder.self)
        Telemetry.default.add(pingBuilderType: FocusEventPingBuilder.self)

        Telemetry.default.recordSessionStart()
        Telemetry.default.recordEvent(
                category: TelemetryEventCategory.action,
                method: TelemetryEventMethod.startup,
                object: TelemetryEventObject.app
        )
    }
}

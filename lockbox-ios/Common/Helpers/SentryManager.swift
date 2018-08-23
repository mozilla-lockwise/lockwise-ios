/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Sentry

class Sentry {
    private let SentryDSNKey = "SentryDSN"

    public static let shared = Sentry()

    init() {
    }

    func setup(sendUsageData: Bool) {
        if isSimulator() || !sendUsageData {
            return
        }

        guard let dsn = Bundle.main.object(forInfoDictionaryKey: SentryDSNKey) as? String, !dsn.isEmpty else {
            return
        }

        do {
            Client.shared = try Client(dsn: dsn)
            try Client.shared?.startCrashHandler()

            // https://docs.sentry.io/clients/cocoa/advanced/#breadcrumbs
            Client.shared?.enableAutomaticBreadcrumbTracking()
        } catch let error {
            print("\(error)")
        }
    }

    private func isSimulator() -> Bool {
        return ProcessInfo.processInfo.environment["SIMULATOR_ROOT"] != nil
    }
}

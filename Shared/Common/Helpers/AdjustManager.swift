/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import AdjustSdk

class AdjustManager {
    let adjust: Adjust

    public static let shared = AdjustManager()

    enum AdjustEvent: String {
        case FxaComplete = "cuahml"
    }

    private var adjustConfig: ADJConfig? {
        #if DEBUG
            return ADJConfig(appToken: Constant.app.adjustAppToken, environment: ADJEnvironmentSandbox)
        #else
            return ADJConfig(appToken: Constant.app.adjustAppToken, environment: ADJEnvironmentProduction)
        #endif
    }

    init() {
        adjust = Adjust()
        adjust.appDidLaunch(self.adjustConfig)
    }

    func trackEvent(_ event: AdjustEvent) {
        self.adjust.trackEvent(ADJEvent(eventToken: event.rawValue))
    }

    func setEnabled(_ enabled: Bool) {
        self.adjust.setEnabled(enabled)
    }
}

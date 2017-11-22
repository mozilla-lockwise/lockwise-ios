/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class TelemetryEventCategory {
    public static let action = "action"
}

class TelemetryEventMethod {
    public static let background = "background"
    public static let foreground = "foreground"
    public static let click = "click"
}

class TelemetryEventObject {
    public static let app = "app"
    public static let initStoreButton = "init_store_button"
    public static let unlockStoreButton = "unlock_store_button"
    public static let listStoreContentsButton = "list_store_contents_button"
}

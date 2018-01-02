/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


import Foundation
import UIKit

struct UIConstants {
    struct strings {
        static let settingsTitle = NSLocalizedString("Settings.title", value: "Settings", comment: "Settings nav title")
        static let settingsHelpSectionHeader = NSLocalizedString("Settings.help.header", value: "HELP", comment: "Help section label in settings")
        static let settingsConfigurationSectionHeader = NSLocalizedString("Settings.configuration.header", value: "CONFIGURATION", comment: "Configuration section label in settings")
        
        static let settingsHelpProvideFeedback = NSLocalizedString("Settings.help.provideFeedback", value: "Provide Feedback", comment: "Provide feedback label in settings")
        static let settingsHelpFAQ = NSLocalizedString("Settings.help.faq", value: "FAQ", comment: "FAQ label in settings")
        static let settingsHelpEnableInBrowser = NSLocalizedString("Settings.help.enableInBrowser", value: "Enable In Browser", comment: "Enable in browser label in settings")
        static let settingsConfigurationAccount = NSLocalizedString("Settings.configuration.account", value: "Account", comment: "Account label in settings")
        static let settingsConfigurationTouchID = NSLocalizedString("Settings.configuration.touchID", value: "Touch ID", comment: "Touch ID label in settings")
        static let settingsConfigurationAutoLock = NSLocalizedString("Settings.configuration.autoLock", value: "Auto Lock", comment: "Auto Lock label in settings")
        static let done = NSLocalizedString("Done", value: "Done", comment: "Label do complete a section of the app")
    }
}

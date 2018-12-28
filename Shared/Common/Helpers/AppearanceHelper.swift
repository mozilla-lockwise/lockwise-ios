/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class AppearanceHelper {
    static let shared = AppearanceHelper()

    func setupAppearance() {
        UINavigationBar.appearance().barTintColor = Constant.color.navBackgroundColor
        UINavigationBar.appearance().isTranslucent = false
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: Constant.color.navTextColor
        ]
        UITextField.appearance().tintColor = .black
    }
}

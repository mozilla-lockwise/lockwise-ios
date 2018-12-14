/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class AppearanceHelper {
    static let shared = AppearanceHelper()

    func setupAppearance() {
        let navBarImage = UIImage.createGradientImage(
            frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height),
            colors: [Constant.color.lockBoxBlue, Constant.color.lockBoxTeal],
            locations: [0.15, 0]
        )
        if #available(iOS 11.0, *) {
            UINavigationBar.appearance().barTintColor = Constant.color.navBackgroundColor
            UINavigationBar.appearance().isTranslucent = false
            UINavigationBar.appearance().prefersLargeTitles = true
            UINavigationBar.appearance().largeTitleTextAttributes = [
                NSAttributedString.Key.foregroundColor: Constant.color.navTextColor
            ]
        } else {
            UINavigationBar.appearance().setBackgroundImage(navBarImage, for: .default)
            UINavigationBar.appearance().isTranslucent = false
        }

        UITextField.appearance().tintColor = .black
    }
}

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

        UINavigationBar.appearance().barTintColor = UIColor(patternImage: navBarImage!)
        UINavigationBar.appearance().isTranslucent = true
        UINavigationBar.appearance().prefersLargeTitles = true
        UINavigationBar.appearance().largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]

        UITextField.appearance().tintColor = .black
    }
}

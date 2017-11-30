/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UINavigationBar {
    func addLockboxGradient() {
        var frameWithStatusBar = self.bounds
        frameWithStatusBar.size.height += UIApplication.shared.statusBarFrame.height
        let gradientImage = UIImage.createGradientImage(frame: frameWithStatusBar, colors: [UIColor.lockBoxTeal, UIColor.lockBoxBlue])
        self.setBackgroundImage(gradientImage, for: .default)
        self.setNeedsLayout()
    }
}
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UIImage {
    static func createGradientImage(frame:CGRect, colors: [UIColor]) -> UIImage? {
        let gradientLayer = CAGradientLayer()
        
        gradientLayer.colors = colors.map({ (color) -> CGColor in
            return color.cgColor
        })
        gradientLayer.frame = frame
        gradientLayer.locations = [0.0, 0.85]
        gradientLayer.startPoint = gradientStartPoint(frame: frame)
        gradientLayer.endPoint = gradientEndPoint(frame: frame)

        var image:UIImage? = nil
        UIGraphicsBeginImageContext(frame.size)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()

        return image
    }
}

fileprivate func gradientStartPoint(frame:CGRect) -> CGPoint {
    return CGPoint(x: 0.4196, y: 0)
}

fileprivate func gradientEndPoint(frame:CGRect) -> CGPoint {
    return CGPoint(x: 0.43636, y: 1)
}

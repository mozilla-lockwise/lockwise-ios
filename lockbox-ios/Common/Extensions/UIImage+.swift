/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UIImage {
    static func createGradientImage(frame: CGRect, colors: [UIColor], locations: [NSNumber] = [0.15, 0]) -> UIImage? {
        let gradientLayer = CAGradientLayer()

        gradientLayer.colors = colors.map({ (color) -> CGColor in
            return color.cgColor
        })
        gradientLayer.frame = frame
        gradientLayer.locations = locations
        gradientLayer.startPoint = gradientStartPoint(frame: frame)
        gradientLayer.endPoint = gradientEndPoint(frame: frame)

        var image: UIImage? = nil
        UIGraphicsBeginImageContext(frame.size)
        if let context = UIGraphicsGetCurrentContext() {
            gradientLayer.render(in: context)
            image = UIGraphicsGetImageFromCurrentImageContext()
        }
        UIGraphicsEndImageContext()

        return image
    }

    func circleCrop(borderColor: UIColor) -> UIImage? {
        let imageView: UIImageView = UIImageView(image: self)
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = borderColor.cgColor

        UIGraphicsBeginImageContext(imageView.bounds.size)
        if let context = UIGraphicsGetCurrentContext() {
            imageView.layer.render(in: context)
        }

        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return roundedImage
    }

    func tinted(_ color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        color.set()
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

private func gradientStartPoint(frame: CGRect) -> CGPoint {
    return CGPoint(x: 0.4196, y: 0)
}

private func gradientEndPoint(frame: CGRect) -> CGPoint {
    return CGPoint(x: 0.43636, y: 1)
}

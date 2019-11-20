//
//  NavigationControllerExtension.swift
//  Lockbox
//
//  Created by Kayla Galway on 11/7/19.
//  Copyright © 2019 Mozilla. All rights reserved.
//

import UIKit

extension UINavigationController {
    
    func iosThirteenNavBarAppearance() {
        if #available(iOS 13.0, *) {
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithOpaqueBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.backgroundColor = Constant.color.navBackgroundColor
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
        }
    }
    
}

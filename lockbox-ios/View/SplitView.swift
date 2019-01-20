/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class SplitView: UISplitViewController {
    init(delegate: UISplitViewControllerDelegate) {
        super.init(nibName: nil, bundle: nil)
        self.preferredDisplayMode = UISplitViewController.DisplayMode.allVisible
        self.delegate = delegate
        self.viewControllers = [
            MainNavigationController(storyboardName: "ItemList", identifier: "itemlist"),
            MainNavigationController(storyboardName: "ItemDetail", identifier: "itemdetailview")
        ]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public var sidebarView: UINavigationController? {
        get {
            return self.viewControllers[0] as? UINavigationController
        }
        set {
            if let navController = newValue {
                self.viewControllers[0] = navController
            }
        }
    }

    public var detailView: UINavigationController? {
        get {
            if self.viewControllers.count != 2 {
                return nil
            }

            return self.viewControllers[1] as? UINavigationController
        }
        set {
            if let viewController = newValue {
                self.viewControllers[1] = viewController
            }
        }
    }
}

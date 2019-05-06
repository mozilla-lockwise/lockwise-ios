/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class MainNavigationController: UINavigationController {
    convenience init(storyboardName: String = "ItemList", identifier: String = "itemlist") {
        let listView = UIStoryboard(name: storyboardName, bundle: .main)
                .instantiateViewController(withIdentifier: identifier)
        self.init(rootViewController: listView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
    }
}

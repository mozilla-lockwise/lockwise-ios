/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class MainNavigationController: UINavigationController {
    convenience init() {
        let listView = UIStoryboard(name: "ItemList", bundle: .main)
                .instantiateViewController(withIdentifier: "itemlist")
        self.init(rootViewController: listView)
    }
}

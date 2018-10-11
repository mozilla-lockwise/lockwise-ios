/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

class ViewFactory {
    public static let shared = ViewFactory()

    func make(storyboardName: String, identifier: String) -> UIViewController {
        return UIStoryboard(name: storyboardName, bundle: nil).instantiateViewController(withIdentifier: identifier)
    }

    func make<T: UIViewController>(_ type: T.Type) -> UIViewController {
        return type.init()
    }
}

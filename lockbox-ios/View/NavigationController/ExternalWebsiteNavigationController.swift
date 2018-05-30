/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class ExternalWebsiteNavigationController: UINavigationController {
    convenience init(urlString: String, title: String, returnRoute: RouteAction) {
        let staticURLWebView = StaticURLWebView(urlString: urlString, title: title, returnRoute: returnRoute)
        self.init(rootViewController: staticURLWebView)
    }
}

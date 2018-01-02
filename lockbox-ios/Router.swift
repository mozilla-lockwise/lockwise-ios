/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class Router {
    static let shared = Router()

    func routeToListViewFromWindow(window: UIWindow) {
        let storyboard = UIStoryboard(name: "ItemList", bundle: Bundle.main)

        let view = storyboard.instantiateInitialViewController() as! ItemListView
        let navController = UINavigationController(rootViewController: view)

        let presenter = ItemListPresenter()

        view.presenter = presenter
        presenter.view = view
        presenter.dataStore = DataStore(webView: &view.webView)

        window.rootViewController = navController
    }
    
    func routeToSettings(window: UIWindow) {
        let vc = SettingsViewController()
        let navController = UINavigationController(rootViewController: vc)
        navController.navigationBar.addLockboxGradient()
        
        window.rootViewController?.present(navController, animated: true) {
            
        }
    }
}

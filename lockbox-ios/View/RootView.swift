/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class RootView: UIViewController, RootViewProtocol {
    internal var presenter: RootPresenter?

    private var currentViewController: UINavigationController? {
        didSet {
            if let currentViewController = self.currentViewController {
                self.addChildViewController(currentViewController)
                currentViewController.view.frame = self.view.bounds
                self.view.addSubview(currentViewController.view)
                currentViewController.didMove(toParentViewController: self)

                if oldValue != nil {
                    self.view.sendSubview(toBack: currentViewController.view)
                }
            }

            guard let oldViewController = oldValue else {
                return
            }
            oldViewController.willMove(toParentViewController: nil)
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParentViewController()
        }
    }

    var loginStackDisplayed: Bool {
        return (self.currentViewController as? LoginNavigationController) != nil
    }

    var mainStackDisplayed: Bool {
        return (self.currentViewController as? MainNavigationController) != nil
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.currentViewController?.topViewController?.preferredStatusBarStyle ?? .lightContent
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        self.presenter = RootPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.onViewReady()
    }

    func topViewIs<T>(_ class: T.Type) -> Bool {
        return self.currentViewController?.topViewController is T
    }

    func startLoginStack() {
        self.currentViewController = LoginNavigationController()
    }

    func pushLoginView(view: LoginRouteAction) {
        switch view {
        case .welcome:
            self.currentViewController?.popToRootViewController(animated: true)
        case .fxa:
            self.currentViewController?.pushViewController(FxAView(), animated: true)
        }
    }

    func startMainStack() {
        self.currentViewController = MainNavigationController()
    }

    func pushMainView(view: MainRouteAction) {
        switch view {
        case .list:
            self.currentViewController?.popToRootViewController(animated: true)
        case .detail(let id):
            guard let itemDetailView = UIStoryboard(name: "ItemDetail", bundle: nil).instantiateViewController(withIdentifier: "itemdetailview") as? ItemDetailView else { // swiftlint:disable:this line_length
                return
            }

            itemDetailView.itemId = id
            self.currentViewController?.pushViewController(itemDetailView, animated: true)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
}

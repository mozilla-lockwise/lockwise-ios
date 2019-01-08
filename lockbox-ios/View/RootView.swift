/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class RootView: UIViewController, RootViewProtocol {
    func sidebarViewIs<T: UIViewController>(_ type: T.Type) -> Bool {
        if let splitViewController = self.currentViewController as? UISplitViewController {
            if let navController = splitViewController.viewControllers.first as? UINavigationController {
                return navController.topViewController is T
            }
        }

        return false
    }

    internal var presenter: RootPresenter?

    private var currentViewController: UIViewController? {
        didSet {
            if let currentViewController = self.currentViewController {
                self.addChild(currentViewController)
                currentViewController.view.frame = self.view.bounds
                self.view.addSubview(currentViewController.view)
                currentViewController.didMove(toParent: self)

                if oldValue != nil {
                    self.view.sendSubviewToBack(currentViewController.view)
                }
            }

            guard let oldViewController = oldValue else {
                return
            }
            oldViewController.willMove(toParent: nil)
            oldViewController.view.removeFromSuperview()
            oldViewController.removeFromParent()
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return self.currentNaivgationController?.topViewController?.preferredStatusBarStyle ?? .lightContent
    }

    private var currentNaivgationController: UINavigationController? {
        if let splitViewController = self.currentViewController as? UISplitViewController {
            if splitViewController.viewControllers.count != 2 {
                return nil
            }

            return splitViewController.viewControllers[1] as? UINavigationController
        }

        return self.currentViewController as? UINavigationController
    }

    init() {
        super.init(nibName: nil, bundle: nil)
        if !isRunningTest {
            self.presenter = RootPresenter(view: self)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.presenter?.onViewReady()
        self.view.backgroundColor = Constant.color.navBackgroundColor
    }

    func topViewIs<T: UIViewController>(_ type: T.Type) -> Bool {
        if let navController = self.currentViewController as? UINavigationController {
            return navController.topViewController is T
        }

        return self.currentViewController is T
    }

    func modalViewIs<T: UIViewController>(_ type: T.Type) -> Bool {
        if let presentedViewController = self.presentedViewController {
            if let navController = presentedViewController as? UINavigationController {
                return navController.topViewController is T
            }

            return presentedViewController is T
        }

        return false
    }

    func mainStackIs<T: UIViewController>(_ type: T.Type) -> Bool {
        return currentViewController is T
    }

    func modalStackIs<T: UINavigationController>(_ type: T.Type) -> Bool {
        return self.currentViewController?.presentedViewController is T
    }

    var modalStackPresented: Bool {
        return self.currentViewController?.presentedViewController is UINavigationController
    }

    func startMainStack<T: UIViewController>(_ viewController: T) {
        self.currentViewController = viewController
    }

    func startModalStack<T: UINavigationController>(_ navigationController: T) {
        self.present(navigationController, animated: !isRunningTest, completion: nil)
    }

    func dismissModals() {
        self.presentedViewController?.dismiss(animated: !isRunningTest, completion: nil)
    }

    func push(view: UIViewController) {
        self.currentNaivgationController?.pushViewController(view, animated: !isRunningTest)
    }

    func popView() {
        self.currentNaivgationController?.popViewController(animated: !isRunningTest)
    }

    func popToRoot() {
        self.currentNaivgationController?.popToRootViewController(animated: !isRunningTest)
    }

    func pushSidebar(view: UIViewController) {
        if let splitView = self.currentViewController as? SplitView {
            splitView.showSidebar(vc: view)
        }
    }

    func pushDetail(view: UIViewController) {
        if let splitView = self.currentViewController as? SplitView {
            splitView.detailView?.setViewControllers([view], animated: false)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
}

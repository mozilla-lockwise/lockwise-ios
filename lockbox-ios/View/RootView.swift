/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class RootView: UIViewController, RootViewProtocol {
    func sidebarViewIs<T: UIViewController>(_ type: T.Type) -> Bool {
        if let splitViewController = self.currentViewController as? UISplitViewController {
            if let navController = splitViewController.viewControllers.first as? UINavigationController {
                return navController.topViewController is T
            } else {
                return splitViewController.viewControllers.first is T
            }
        }

        return false
    }

    func detailViewIs<T: UIViewController>(_ type: T.Type) -> Bool {
        if let splitViewController = self.currentViewController as? SplitView {
            if let navController = splitViewController.detailView {
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
        return self.currentNavigationController?.topViewController?.preferredStatusBarStyle ?? .lightContent
    }

    private var currentNavigationController: UINavigationController? {
        if let splitViewController = self.currentViewController as? SplitView {
            return splitViewController.sidebarView
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
        if let navController = self.currentNavigationController {
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

    func modalStackIs<T: UIViewController>(_ type: T.Type) -> Bool {
        return self.currentViewController?.presentedViewController is T
    }

    var modalStackPresented: Bool {
        return self.currentViewController?.presentedViewController is UINavigationController
    }

    func startMainStack<T: UIViewController>(_ viewController: T) {
        self.currentViewController = viewController
    }

    func startModalStack<T: UIViewController>(_ viewController: T) {
        self.currentViewController?.present(viewController, animated: !isRunningTest, completion: nil)
    }

    func dismissModals() {
        self.currentViewController?.presentedViewController?.dismiss(animated: !isRunningTest, completion: nil)
    }

    func push(view: UIViewController) {
        self.currentNavigationController?.pushViewController(view, animated: !isRunningTest)
    }

    func popView() {
        self.currentNavigationController?.popViewController(animated: !isRunningTest)
    }

    func popToRoot() {
        self.currentNavigationController?.popToRootViewController(animated: !isRunningTest)
    }

    func pushSidebar(view: UIViewController) {
        if let splitView = self.currentViewController as? SplitView {
            splitView.sidebarView = MainNavigationController(rootViewController: view)
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

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        self.presenter?.changeDisplay(traitCollection: newCollection)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        self.presenter?.changeDisplay(traitCollection: traitCollection)
    }
}

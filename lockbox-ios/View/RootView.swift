/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
 // swiftlint:disable line_length

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

    func sidebarStackIs<T: UINavigationController>(_ type: T.Type) -> Bool {
        if let splitViewController = self.currentViewController as? UISplitViewController {
            if let navController = splitViewController.viewControllers.last as? UINavigationController {
                return navController is T
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

//    private var mainNavigationController: UINavigationController? {
//        if let currentViewController = self.currentViewController as? UINavigationController {
//            return currentViewController
//        }
//
//        if let currentViewController = self.currentViewController as? UISplit
//    }



//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        return self.currentViewController?.topViewController?.preferredStatusBarStyle ?? .lightContent
//    }

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
    }

    func showSidebar() {
        if self.currentViewController is UISplitViewController {
            return
        }

        let splitViewController = UISplitViewController()
        splitViewController.viewControllers = [UINavigationController(), UINavigationController()]
        splitViewController.preferredDisplayMode = .allVisible
        self.currentViewController = splitViewController
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
//        if let splitViewController = currentViewController as? UISplitViewController {
//            if splitViewController.viewControllers.count != 2 {
//                return false
//            }
//
//            return splitViewController.viewControllers[1] is T
//        }

        return currentViewController is T
    }

    func modalStackIs<T: UINavigationController>(_ type: T.Type) -> Bool {
        return self.currentViewController?.presentedViewController is T
    }

    var modalStackPresented: Bool {
        return self.currentViewController?.presentedViewController is UINavigationController
    }

    func startSidebarStack<T: UINavigationController>(_ navigationController: T) {
        if let splitViewController = self.currentViewController as? UISplitViewController {
            splitViewController.viewControllers[0] = navigationController
        }
//        (self.currentViewController as? UISplitViewController)?.show(navigationController, sender: self)
    }

    func startMainStack<T: UIViewController>(_ viewController: T) {
//        if let splitViewController = self.currentViewController as? UISplitViewController {
////            splitViewController.showDetailViewController(navigationController, sender: self)
//            splitViewController.viewControllers[1] = navigationController
//        } else {
            self.currentViewController = viewController
//        }
    }

    func startModalStack<T: UINavigationController>(_ navigationController: T) {
        self.present(navigationController, animated: !isRunningTest, completion: nil)
    }

    func dismissModals() {
        self.presentedViewController?.dismiss(animated: !isRunningTest, completion: nil)
    }

    func pushLoginView(view: LoginRouteAction) {
        switch view {
        case .welcome:
            self.currentNaivgationController?.popToRootViewController(animated: !isRunningTest)
        case .fxa:
            self.currentNaivgationController?.pushViewController(FxAView(), animated: !isRunningTest)
        case .onboardingConfirmation:
            if let onboardingConfirmationView = UIStoryboard(name: "OnboardingConfirmation", bundle: nil).instantiateViewController(withIdentifier: "onboardingconfirmation") as? OnboardingConfirmationView {
                self.currentNaivgationController?.pushViewController(onboardingConfirmationView, animated: !isRunningTest)
            }
        case .autofillOnboarding:
            if let autofillOnboardingView = UIStoryboard(name: "AutofillOnboarding", bundle: nil).instantiateViewController(withIdentifier: "autofillonboarding") as? AutofillOnboardingView {
                self.currentNaivgationController?.pushViewController(autofillOnboardingView, animated: !isRunningTest)
            }
        case .autofillInstructions:
            if let autofillInstructionsView = UIStoryboard(name: "SetupAutofill", bundle: nil).instantiateViewController(withIdentifier: "autofillinstructions") as? AutofillInstructionsView {
                self.currentNaivgationController?.pushViewController(autofillInstructionsView, animated: !isRunningTest)
            }
        }
    }

    func pushSidebarView(view: MainRouteAction) {
        switch view {
        case .list:
            if let splitViewController = self.currentViewController as? UISplitViewController {
                (splitViewController.viewControllers.first as? UINavigationController)?.popToRootViewController(animated: !isRunningTest)
            }
        case .detail:
            break
        }
    }

    func pushMainView(view: MainRouteAction) {
        switch view {
        case .list:
            self.currentNaivgationController?.popToRootViewController(animated: !isRunningTest)
        case .detail(let id):
            if let itemDetailView = UIStoryboard(name: "ItemDetail", bundle: nil).instantiateViewController(withIdentifier: "itemdetailview") as? ItemDetailView {
                itemDetailView.itemId = id

                self.currentNaivgationController?.pushViewController(itemDetailView, animated: !isRunningTest)
            }
        }
    }

    func pushDetailView(view: MainRouteAction) {
        switch view {
        case .detail(let id):
            if let itemDetailView = UIStoryboard(name: "ItemDetail", bundle: nil).instantiateViewController(withIdentifier: "itemdetailview") as? ItemDetailView {
                itemDetailView.itemId = id

                if let splitView = self.currentViewController as? SplitView {
                    splitView.detailView?.setViewControllers([itemDetailView], animated: false)
                }
            }
        case .list:
            break
        }
    }

    func pushSettingView(view: SettingRouteAction) {
        switch view {
        case .list:
            self.currentNaivgationController?.popToRootViewController(animated: !isRunningTest)
        case .account:
            if let accountSettingView = UIStoryboard(name: "AccountSetting", bundle: nil).instantiateViewController(withIdentifier: "accountsetting") as? AccountSettingView {
                self.currentNaivgationController?.pushViewController(accountSettingView, animated: !isRunningTest)
            }
        case .autoLock:
            self.currentNaivgationController?.pushViewController(AutoLockSettingView(), animated: !isRunningTest)
        case .preferredBrowser:
            self.currentNaivgationController?.pushViewController(PreferredBrowserSettingView(), animated: !isRunningTest)
        case .autofillInstructions:
            if let autofillSettingView = UIStoryboard(name: "SetupAutofill", bundle: nil).instantiateViewController(withIdentifier: "autofillinstructions") as? AutofillInstructionsView {
                self.currentNaivgationController?.pushViewController(autofillSettingView, animated: !isRunningTest)
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
}

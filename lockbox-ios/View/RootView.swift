/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
 // swiftlint:disable line_length

import UIKit

class RootView: UIViewController, RootViewProtocol {
    internal var presenter: RootPresenter?

    private var currentViewController: UINavigationController? {
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
        return self.currentViewController?.topViewController?.preferredStatusBarStyle ?? .lightContent
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

    func topViewIs<T: UIViewController>(_ type: T.Type) -> Bool {
        return self.currentViewController?.topViewController is T
    }

    func modalViewIs<T: UIViewController>(_ type: T.Type) -> Bool {
        return (self.currentViewController?.presentedViewController as? UINavigationController)?.topViewController is T
    }

    func mainStackIs<T: UINavigationController>(_ type: T.Type) -> Bool {
        return self.currentViewController is T
    }

    func modalStackIs<T: UINavigationController>(_ type: T.Type) -> Bool {
        return self.currentViewController?.presentedViewController is T
    }

    var modalStackPresented: Bool {
        return self.currentViewController?.presentedViewController is UINavigationController
    }

    func startMainStack<T: UINavigationController>(_ type: T.Type) {
        self.currentViewController = type.init()
    }

    func startModalStack<T: UINavigationController>(_ navigationController: T) {
        self.currentViewController?.present(navigationController, animated: true)
    }

    func dismissModals() {
        self.currentViewController?.presentedViewController?.dismiss(animated: !isRunningTest, completion: nil)
    }

    func pushLoginView(view: LoginRouteAction) {
        switch view {
        case .welcome:
            self.currentViewController?.popToRootViewController(animated: !isRunningTest)
        case .fxa:
            self.currentViewController?.pushViewController(FxAView(), animated: !isRunningTest)
        case .onboardingConfirmation:
            if let onboardingConfirmationView = UIStoryboard(name: "OnboardingConfirmation", bundle: nil).instantiateViewController(withIdentifier: "onboardingconfirmation") as? OnboardingConfirmationView {
                self.currentViewController?.pushViewController(onboardingConfirmationView, animated: !isRunningTest)
            }
        }
    }

    func pushMainView(view: MainRouteAction) {
        switch view {
        case .list:
            self.currentViewController?.popToRootViewController(animated: !isRunningTest)
        case .detail(let id):
            if let itemDetailView = UIStoryboard(name: "ItemDetail", bundle: nil).instantiateViewController(withIdentifier: "itemdetailview") as? ItemDetailView {
                itemDetailView.itemId = id
                self.currentViewController?.pushViewController(itemDetailView, animated: !isRunningTest)
            }
        }
    }

    func pushSettingView(view: SettingRouteAction) {
        switch view {
        case .list:
            self.currentViewController?.popToRootViewController(animated: !isRunningTest)
        case .account:
            if let accountSettingView = UIStoryboard(name: "AccountSetting", bundle: nil).instantiateViewController(withIdentifier: "accountsetting") as? AccountSettingView {
                self.currentViewController?.pushViewController(accountSettingView, animated: !isRunningTest)
            }
        case .autoLock:
            self.currentViewController?.pushViewController(AutoLockSettingView(), animated: !isRunningTest)
        case .preferredBrowser:
            self.currentViewController?.pushViewController(PreferredBrowserSettingView(), animated: !isRunningTest)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
}

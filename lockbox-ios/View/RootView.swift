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

    func startMainStack<T: UINavigationController>(_ type: T.Type) {
        self.currentViewController = type.init()
    }

    func startModalStack<T: UINavigationController>(_ type: T.Type) {
        self.currentViewController?.present(type.init(), animated: true)
    }

    func dismissModals() {
        self.currentViewController?.presentedViewController?.dismiss(animated: true, completion: nil)
    }

    func pushLoginView(view: LoginRouteAction) {
        switch view {
        case .welcome:
            self.currentViewController?.popToRootViewController(animated: true)
        case .fxa:
            self.currentViewController?.pushViewController(FxAView(), animated: true)
        case .learnMore:
            self.currentViewController?.pushViewController(StaticURLWebView(url: Constant.app.useLockboxFAQ,
                                                                          title: Constant.string.learnMore),
                                                           animated: true)
        }
    }

    func pushMainView(view: MainRouteAction) {
        switch view {
        case .list:
            self.currentViewController?.popToRootViewController(animated: true)
        case .detail(let id):
            if let itemDetailView = UIStoryboard(name: "ItemDetail", bundle: nil).instantiateViewController(withIdentifier: "itemdetailview") as? ItemDetailView { // swiftlint:disable:this line_length
                itemDetailView.itemId = id
                self.currentViewController?.pushViewController(itemDetailView, animated: true)
            }
        case .learnMore:
            self.currentViewController?.pushViewController(
                    StaticURLWebView(
                            url: Constant.app.enableSyncFAQ,
                            title: Constant.string.learnMore),
                    animated: true)
        }
    }

    func pushSettingView(view: SettingRouteAction) {
        let settingNavController = (self.currentViewController?.presentedViewController as? UINavigationController)

        switch view {
        case .list:
            settingNavController?.popToRootViewController(animated: true)
        case .account:
            if let accountSettingView = UIStoryboard(name: "AccountSetting", bundle: nil).instantiateViewController(withIdentifier: "accountsetting") as? AccountSettingView { // swiftlint:disable:this line_length
                settingNavController?.pushViewController(accountSettingView, animated: true)
            }
        case .autoLock:
            settingNavController?.pushViewController(AutoLockSettingView(), animated: true)
        case .preferredBrowser:
            settingNavController?.pushViewController(PreferredBrowserSettingView(), animated: true)
        case .faq:
            settingNavController?.pushViewController(
                StaticURLWebView(url: Constant.app.faqURL, title: Constant.string.settingsFaq), animated: true)
        case .provideFeedback:
            settingNavController?.pushViewController(
                StaticURLWebView(url: Constant.app.provideFeedbackURL,
                                title: Constant.string.settingsProvideFeedback), animated: true)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
}

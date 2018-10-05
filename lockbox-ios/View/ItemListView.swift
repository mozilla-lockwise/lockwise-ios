/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class ItemListView: BaseItemListView {
    var presenter: ItemListPresenter? {
        return self.basePresenter as? ItemListPresenter
    }

    private var dataSource: RxTableViewSectionedAnimatedDataSource<ItemSectionModel>?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.basePresenter = ItemListPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRefresh()
        self.presenter?.onViewReady()
    }

    override func styleNavigationBar() {
        super.styleNavigationBar()

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.prefButton)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.sortingButton)
    }

    override func createPresenter() -> BaseItemListPresenter {
        return ItemListPresenter(view: self)
    }
}

extension ItemListView: ItemListViewProtocol {
    func bind(sortingButtonTitle: Driver<String>) {
        if let button = self.navigationItem.leftBarButtonItem?.customView as? UIButton {
            sortingButtonTitle
                .drive(button.rx.title())
                .disposed(by: self.disposeBag)

            sortingButtonTitle
                .drive(onNext: { title in
                    button.accessibilityLabel = String(
                        format: Constant.string.sortOptionsAccessibilityID,
                        title)
                })
                .disposed(by: self.disposeBag)
        }
    }

    var tableViewScrollEnabled: AnyObserver<Bool> {
        return self.tableView.rx.isScrollEnabled.asObserver()
    }

    var pullToRefreshActive: AnyObserver<Bool>? {
        return self.tableView.refreshControl!.rx.isRefreshing.asObserver()
    }

    var sortingButtonEnabled: AnyObserver<Bool>? {
        if let button = self.navigationItem.leftBarButtonItem?.customView as? UIButton {
            return button.rx.isEnabled.asObserver()
        }

        return nil
    }
    
    var onSettingsButtonPressed: ControlEvent<Void>? {
        if let button = self.navigationItem.rightBarButtonItem?.customView as? UIButton {
            return button.rx.tap
        }
        
        return nil
    }
    
    var onSortingButtonPressed: ControlEvent<Void>? {
        if let button = self.navigationItem.leftBarButtonItem?.customView as? UIButton {
            return button.rx.tap
        }
        
        return nil
    }
}

extension ItemListView {
    fileprivate func setupRefresh() {
        if let presenter = self.presenter {
            let refreshControl = UIRefreshControl()
            self.tableView.refreshControl = refreshControl
            refreshControl.rx.controlEvent(.valueChanged)
                .bind(to: presenter.refreshObserver)
                .disposed(by: self.disposeBag)
        }
    }
}

// view styling
extension ItemListView {
    private var prefButton: UIButton {
        let button = UIButton()
        button.accessibilityIdentifier = "settings.button"
        let prefImage = UIImage(named: "preferences")?.withRenderingMode(.alwaysTemplate)
        button.accessibilityLabel = Constant.string.settingsAccessibilityID
        let tintedPrefImage = prefImage?.tinted(UIColor(white: 1.0, alpha: 0.6))
        button.setImage(prefImage, for: .normal)
        button.setImage(tintedPrefImage, for: .selected)
        button.setImage(tintedPrefImage, for: .highlighted)
        button.setImage(tintedPrefImage, for: .disabled)
        button.contentEdgeInsets = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 0.0)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private var sortingButton: UIButton {
        let button = UIButton(title: Constant.string.aToZ, imageName: "down-caret")
        button.titleLabel?.font = .navigationButtonFont
        // custom width constraint so "Recent" fits on small iPhone SE screen
        button.accessibilityIdentifier = "sorting.button"
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addConstraint(NSLayoutConstraint(
            item: button,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: 60)
        )
        return button
    }
}

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

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return super.preferredStatusBarStyle
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.basePresenter = ItemListPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupRefresh()
        setupSwipeDelete()
        presenter?.onViewReady()
        backgroundModeObserver()
    }

    override func styleNavigationBar() {
        super.styleNavigationBar()

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.prefButton)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.sortingButton)
    }

    override func createPresenter() -> BaseItemListPresenter {
        return ItemListPresenter(view: self)
    }
    
    private func backgroundModeObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(scrollTableViewToTop),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
    }
    
    @objc private func scrollTableViewToTop() {
        if (self.tableView.numberOfRows(inSection: 0) > 0) {
            DispatchQueue.main.async {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0),
                                           at: UITableView.ScrollPosition.top,
                                           animated: true)
            }
        }
    }
}

extension ItemListView: ItemListViewProtocol {
    var sortButton: UIBarButtonItem? {
        return navigationItem.leftBarButtonItem
    }

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

    func bind(scrollAction: Driver<ScrollAction>) {
        scrollAction.delay(.milliseconds(100))
                    .drive(onNext: { action in
                        guard self.tableView.dataSource?.tableView(self.tableView, numberOfRowsInSection: 0) ?? 0 > 0 else { return }
                        switch action {
                        case .toTop:
                            self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .none, animated: true)
                        }
                    })
                    .disposed(by: self.disposeBag)
    }

    func showDeletedStatusAlert(message: String) {
        DispatchQueue.main.async {
            let icon = UIImage(named: "delete")
            self.displayTemporaryAlert(message, timeout: Constant.number.displayStatusAlertLength.timeInterval(), icon: icon)
        }
    }

    var tableViewScrollEnabled: AnyObserver<Bool> {
        return tableView.rx.isScrollEnabled.asObserver()
    }

    var pullToRefreshActive: AnyObserver<Bool>? {
        return tableView.refreshControl!.rx.isRefreshing.asObserver()
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

    var itemDeleted: Observable<String> {
        return self.tableView.rx.itemDeleted
            .map { (path: IndexPath) -> String? in
                self.tableView.deselectRow(at: path, animated: false)
                guard let config = self.dataSource?[path] else {
                    return nil
                }

                switch config {
                case .Item(_, _, let id, _):
                    return id
                default:
                    return nil
                }
        }.filterNil()
    }
}

extension ItemListView {
    fileprivate func setupRefresh() {
        if let presenter = self.presenter {
            let refreshControl = UIRefreshControl()
            refreshControl.tintColor = Constant.color.systemLightGray
            tableView.refreshControl = refreshControl
            refreshControl.rx.controlEvent(.valueChanged)
                .bind(to: presenter.refreshObserver)
                .disposed(by: self.disposeBag)
        }
    }

    fileprivate func setupSwipeDelete() {
        self.dataSource?.canEditRowAtIndexPath = { dataSource, indexPath in
            let config = dataSource[indexPath]

            switch config {
            case .Item:
                return true
            default:
                return false
            }
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
            relatedBy: .greaterThanOrEqual,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: 60)
        )
        return button
    }
}

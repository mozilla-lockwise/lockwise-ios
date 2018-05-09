/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

typealias ItemSectionModel = AnimatableSectionModel<Int, LoginListCellConfiguration>

enum LoginListCellConfiguration {
    case Search
    case Item(title: String, username: String, guid: String?)
}

extension LoginListCellConfiguration: IdentifiableType {
    var identity: String {
        switch self {
        case .Search:
            return "search"
        case .Item(let title, _, _):
            return title
        }
    }
}

extension LoginListCellConfiguration: Equatable {
    static func ==(lhs: LoginListCellConfiguration, rhs: LoginListCellConfiguration) -> Bool {
        switch (lhs, rhs) {
        case (.Search, .Search): return true
        case (.Item(let lhTitle, let lhUsername, _), .Item(let rhTitle, let rhUsername, _)):
            return lhTitle == rhTitle && lhUsername == rhUsername
        default:
            return false
        }
    }
}

class ItemListView: UIViewController {
    var presenter: ItemListPresenter?
    @IBOutlet weak var tableView: UITableView!
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedAnimatedDataSource<ItemSectionModel>?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = ItemListPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupRefresh()
        self.styleTableViewBackground()
        self.styleNavigationBar()
        self.setupDataSource()
        self.setupDelegate()
        self.presenter?.onViewReady()
    }
}

extension ItemListView: ItemListViewProtocol {
    func bind(items: Driver<[ItemSectionModel]>) {
        if let dataSource = self.dataSource {
            items.drive(self.tableView.rx.items(dataSource: dataSource)).disposed(by: self.disposeBag)
        }
    }

    func bind(sortingButtonTitle: Driver<String>) {
        if let button = self.navigationItem.leftBarButtonItem?.customView as? UIButton {
            sortingButtonTitle
                    .drive(button.rx.title())
                    .disposed(by: self.disposeBag)
        }
    }

    func displayEmptyStateMessaging() {
        if let emptyStateView = Bundle.main.loadNibNamed("EmptyList", owner: self)?[0] as? UIView {
            self.tableView.backgroundView?.addSubview(emptyStateView)
            self.tableView.isScrollEnabled = false
        }

        if let button = self.navigationItem.leftBarButtonItem?.customView as? UIButton {
            button.isHidden = true
        }

    }

    func hideEmptyStateMessaging() {
        self.tableView.backgroundView?.subviews.forEach({ $0.removeFromSuperview() })
        self.tableView.isScrollEnabled = true

        if let button = self.navigationItem.leftBarButtonItem?.customView as? UIButton {
            button.isHidden = false
        }
    }

    func dismissKeyboard() {
        if let cell = self.getFilterCell() {
            cell.filterTextField.resignFirstResponder()
        }
    }

    func displayFilterCancelButton() {
        if let cell = self.getFilterCell() {
            cell.cancelButton.isHidden = false
        }
    }

    func hideFilterCancelButton() {
        if let cell = self.getFilterCell() {
            cell.cancelButton.isHidden = true
        }
    }

    private func getFilterCell() -> FilterCell? {
        return self.tableView.cellForRow(at: [0, 0]) as? FilterCell
    }
}

extension ItemListView {
    fileprivate func setupDataSource() {
        self.dataSource = RxTableViewSectionedAnimatedDataSource<ItemSectionModel>(
                configureCell: { dataSource, tableView, path, _ in
                    let cellConfiguration = dataSource[path]

                    var retCell: UITableViewCell
                    switch cellConfiguration {
                    case .Search:
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: "filtercell") as? FilterCell,
                              let presenter = self.presenter else {
                            fatalError("couldn't find the right cell or presenter!")
                        }

                        cell.filterTextField.rx.text
                                .orEmpty
                                .asObservable()
                                .bind(to: presenter.filterTextObserver)
                                .disposed(by: cell.disposeBag)

                        cell.cancelButton.rx.tap.bind(to: presenter.filterCancelObserver).disposed(by: cell.disposeBag)

                        retCell = cell
                    case .Item(let title, let username, _):
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemlistcell") as? ItemListCell else { // swiftlint:disable:this line_length
                            fatalError("couldn't find the right cell!")
                        }

                        cell.titleLabel.text = title
                        cell.detailLabel.text = username

                        retCell = cell
                    }

                    return retCell
                })

        self.dataSource?.animationConfiguration = AnimationConfiguration(
                insertAnimation: .fade,
                reloadAnimation: .automatic,
                deleteAnimation: .fade
        )
    }

    fileprivate func setupDelegate() {
        if let presenter = self.presenter {
            self.tableView.rx.itemSelected
                    .map { (path: IndexPath) -> String? in
                        guard let config = self.dataSource?[path] else {
                            return nil
                        }

                        switch config {
                        case .Item(_, _, let id):
                            return id
                        default:
                            return nil
                        }
                    }
                    .bind(to: presenter.itemSelectedObserver)
                    .disposed(by: self.disposeBag)
        }
    }

    fileprivate func setupRefresh() {
        if let presenter = self.presenter {
            let button =  UIButton(type: .custom)
            button.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
            button.setTitle(Constant.string.yourLockbox, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)

            button.rx.tap
                    .bind(to: presenter.refreshObserver)
                    .disposed(by: self.disposeBag)

            self.navigationItem.titleView = button
        }
    }
}

// view styling
extension ItemListView {
    fileprivate func styleNavigationBar() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: self.prefButton)
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: self.sortingButton)

        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        if let presenter = presenter {
            (self.navigationItem.rightBarButtonItem?.customView as? UIButton)?.rx.tap
                    .bind(to: presenter.onSettingsTapped)
                    .disposed(by: self.disposeBag)

            (self.navigationItem.leftBarButtonItem?.customView as? UIButton)?.rx.tap
                    .bind(to: presenter.sortingButtonObserver)
                    .disposed(by: self.disposeBag)
        }
    }

    fileprivate func styleTableViewBackground() {
        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.backgroundColor = Constant.color.viewBackground
        self.tableView.backgroundView = backgroundView
    }

    private var prefButton: UIButton {
        let button = UIButton()
        let prefImage = UIImage(named: "preferences")?.withRenderingMode(.alwaysTemplate)
        let tintedPrefImage = prefImage?.tinted(UIColor(white: 1.0, alpha: 0.6))
        button.setImage(prefImage, for: .normal)
        button.setImage(tintedPrefImage, for: .selected)
        button.setImage(tintedPrefImage, for: .highlighted)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private var sortingButton: UIButton {
        let button = UIButton()
        button.adjustsImageWhenHighlighted = false

        let sortingImage = UIImage(named: "down-caret")?.withRenderingMode(.alwaysTemplate)
        button.setImage(sortingImage, for: .normal)
        button.setTitle(Constant.string.aToZ, for: .normal)

        button.contentHorizontalAlignment = .left
        button.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -20)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(UIColor(white: 1.0, alpha: 0.6), for: .highlighted)
        button.setTitleColor(UIColor(white: 1.0, alpha: 0.6), for: .selected)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false

        button.addConstraint(NSLayoutConstraint(
                item: button,
                attribute: .width,
                relatedBy: .equal,
                toItem: nil,
                attribute: .notAnAttribute,
                multiplier: 1.0,
                constant: 100)
        )
        return button
    }
}

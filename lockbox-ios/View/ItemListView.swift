/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

typealias ItemSectionModel = AnimatableSectionModel<Int, ItemCellConfiguration>

struct ItemCellConfiguration {
    let title: String
    let username: String
    let id: String?
}

extension ItemCellConfiguration: IdentifiableType {
    var identity: String {
        return self.title
    }
}

extension ItemCellConfiguration: Equatable {
    static func ==(lhs: ItemCellConfiguration, rhs: ItemCellConfiguration) -> Bool {
        return lhs.username == rhs.username &&
                lhs.title == rhs.title
    }
}

class ItemListView: UIViewController {
    var presenter: ItemListPresenter?
    @IBOutlet weak var tableView: UITableView!
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<ItemSectionModel>?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = ItemListPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleTableViewBackground()
        self.styleNavigationBar()
        self.setupDataSource()
        self.setupDelegate()
        self.presenter?.onViewReady()
    }
}

extension ItemListView: ItemListViewProtocol {
    func bind(items: Driver<[ItemSectionModel]>) {
        guard let dataSource = self.dataSource else {
            fatalError("dataSource not set!")
        }

        items.drive(self.tableView.rx.items(dataSource: dataSource)).disposed(by: self.disposeBag)
    }

    func displayEmptyStateMessaging() {
        guard let emptyStateView = Bundle.main.loadNibNamed("EmptyList", owner: self)?[0] as? UIView else {
            return
        }
        self.tableView.backgroundView?.addSubview(emptyStateView)
    }

    func hideEmptyStateMessaging() {
        self.tableView.backgroundView?.subviews.forEach({ $0.removeFromSuperview() })
    }
}

extension ItemListView {
    fileprivate func setupDataSource() {
        self.dataSource = RxTableViewSectionedReloadDataSource<ItemSectionModel>(
                configureCell: { _, tableView, _, item in
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemlistcell") as? ItemListCell else { // swiftlint:disable:this line_length
                        fatalError("couldn't find the right cell!")
                    }

                    cell.titleLabel.text = item.title
                    cell.detailLabel.text = item.username

                    return cell
                })
    }

    fileprivate func setupDelegate() {
        guard let presenter = self.presenter else {
            return
        }

        self.tableView.rx.itemSelected
                .map { (path: IndexPath) -> String? in
                    return self.dataSource?[path].id
                }
                .bind(to: presenter.itemSelectedObserver)
                .disposed(by: self.disposeBag)
    }
}

// view styling
extension ItemListView {
    fileprivate func styleNavigationBar() {
        let prefButton = UIButton()
        let prefImage = UIImage(named: "preferences")?.withRenderingMode(.alwaysTemplate)
        prefButton.setImage(prefImage, for: .normal)
        prefButton.tintColor = .white

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: prefButton)
        self.navigationItem.title = Constant.string.yourLockbox

        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
    }

    fileprivate func styleTableViewBackground() {
        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.backgroundColor = Constant.color.lightGrey
        self.tableView.backgroundView = backgroundView
    }
}

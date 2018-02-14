/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

typealias ItemDetailSectionModel = AnimatableSectionModel<Int, ItemDetailCellConfiguration>

struct ItemDetailCellConfiguration {
    let title: String
    let value: String
    let password: Bool
}

extension ItemDetailCellConfiguration: IdentifiableType {
    var identity: String {
        return self.title
    }
}

extension ItemDetailCellConfiguration: Equatable {
    static func ==(lhs: ItemDetailCellConfiguration, rhs: ItemDetailCellConfiguration) -> Bool {
        return lhs.value == rhs.value
    }
}

class ItemDetailView: UITableViewController {
    internal var presenter: ItemDetailPresenter?
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<ItemDetailSectionModel>?
    var itemId: String = ""

    private var passwordCell: ItemDetailCell? {
        didSet {
            guard let presenter = self.presenter,
                  let cell = self.passwordCell else {
                return
            }

            cell.revealButton.rx.tap
                    .do(onNext: { _ in
                        cell.revealButton.isSelected = !cell.revealButton.isSelected
                    })
                    .bind(to: presenter.onPasswordToggle)
                    .disposed(by: self.disposeBag)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = ItemDetailPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.styleNavigationBar()
        self.styleTableBackground()
        self.setupDataSource()
        self.presenter?.onViewReady()
    }
}

extension ItemDetailView: ItemDetailViewProtocol {
    var passwordRevealed: Bool {
        guard let cell = self.passwordCell else {
            return false
        }
        return cell.revealButton.isSelected
    }

    func bind(itemDetail: Driver<[ItemDetailSectionModel]>) {
        guard let dataSource = self.dataSource else {
            fatalError("datasource not set!")
        }

        itemDetail
                .drive(self.tableView.rx.items(dataSource: dataSource))
                .disposed(by: self.disposeBag)
    }

    func bind(titleText: Driver<String>) {
        titleText
                .drive(self.navigationItem.rx.title)
                .disposed(by: self.disposeBag)
    }
}

// view styling
extension ItemDetailView {
    fileprivate func styleNavigationBar() {
        let leftButton = UIBarButtonItem(title: Constant.string.back, style: .plain, target: nil, action: nil)
        self.navigationItem.leftBarButtonItem = leftButton

        leftButton.setTitleTextAttributes([
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .regular)
        ], for: .normal)
        self.navigationController?.navigationBar.tintColor = .white

        guard let presenter = self.presenter else {
            return
        }
        leftButton.rx.tap
                .bind(to: presenter.onCancel)
                .disposed(by: self.disposeBag)
    }

    fileprivate func styleTableBackground() {
        guard let disclaimerView = Bundle.main.loadNibNamed("EntryEditDisclaimer", owner: self)?[0] as? UIView else {
            return
        }
        self.tableView.backgroundView = disclaimerView
    }

    fileprivate func setupDataSource() {
        self.dataSource = RxTableViewSectionedReloadDataSource<ItemDetailSectionModel>(
                configureCell: { _, tableView, _, cellConfiguration in
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemdetailcell") as? ItemDetailCell else { // swiftlint:disable:this line_length
                        fatalError("couldn't find the right cell!")
                    }

                    cell.titleLabel.text = cellConfiguration.title
                    cell.valueLabel.text = cellConfiguration.value

                    cell.revealButton.isHidden = !cellConfiguration.password

                    if cellConfiguration.password && self.passwordCell == nil {
                        self.passwordCell = cell
                    }

                    if cellConfiguration.password {
                        cell.valueLabel.font = UIFont(name: "Menlo-Regular", size: 16)
                    }

                    return cell
                })
    }
}

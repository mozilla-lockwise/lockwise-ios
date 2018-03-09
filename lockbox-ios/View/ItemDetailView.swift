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

class ItemDetailView: UIViewController {
    internal var presenter: ItemDetailPresenter?
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<ItemDetailSectionModel>?
    @IBOutlet weak var tableView: UITableView!
    var itemId: String = ""

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
        self.setupDelegate()
        self.presenter?.onViewReady()
    }
}

extension ItemDetailView: ItemDetailViewProtocol {
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
        let leftButton = UIButton()
        leftButton.setTitle(Constant.string.back, for: .normal)
        leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .regular)

        leftButton.setTitleColor(.white, for: .normal)
        leftButton.setTitleColor(Constant.color.lightGrey, for: .selected)
        leftButton.setTitleColor(Constant.color.lightGrey, for: .highlighted)

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)

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

                    passwordConfig:if cellConfiguration.password {
                        cell.valueLabel.font = UIFont(name: "Menlo-Regular", size: 16)

                        guard let presenter = self.presenter else {
                            break passwordConfig
                        }

                        cell.revealButton.rx.tap
                                .map { _ -> Bool in
                                    cell.revealButton.isSelected = !cell.revealButton.isSelected

                                    return cell.revealButton.isSelected
                                }
                                .bind(to: presenter.onPasswordToggle)
                                .disposed(by: cell.disposeBag)
                    }

                    return cell
                })
    }

    fileprivate func setupDelegate() {
        guard let presenter = self.presenter else {
            return
        }

        self.tableView.rx.itemSelected
                .map { path -> String? in
                    guard let selectedCell = self.tableView.cellForRow(at: path) as? ItemDetailCell else {
                        return nil
                    }

                    return selectedCell.titleLabel.text
                }
                .bind(to: presenter.onCellTapped)
                .disposed(by: self.disposeBag)
    }
}

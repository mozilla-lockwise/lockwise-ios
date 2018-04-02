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
    let size: CGFloat
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
        self.setupNavigation()
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
extension ItemDetailView: UIGestureRecognizerDelegate {
    fileprivate func setupNavigation() {
        let leftButton = UIButton()

        let leftImage = UIImage(named: "back-button")?.withRenderingMode(.alwaysTemplate)
        leftButton.setImage(leftImage, for: .normal)
        leftButton.setTitle(Constant.string.back, for: .normal)

        leftButton.contentHorizontalAlignment = .left
        leftButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        leftButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: -20)
        leftButton.setTitleColor(.white, for: .normal)
        leftButton.setTitleColor(.lightGray, for: .selected)
        leftButton.setTitleColor(.lightGray, for: .highlighted)
        leftButton.tintColor = .white

        leftButton.addConstraint(NSLayoutConstraint(
            item: leftButton,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1.0,
            constant: 100)
        )

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)

        guard let presenter = self.presenter else {
            return
        }

        leftButton.rx.tap
                .bind(to: presenter.onCancel)
                .disposed(by: self.disposeBag)

        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.interactivePopGestureRecognizer?.rx.event
                .map { _ -> Void in
                    return ()
                }
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

                    cell.valueLabel.font = cell.valueLabel.font.withSize(cellConfiguration.size)

                    cell.revealButton.isHidden = !cellConfiguration.password

                    passwordConfig:if cellConfiguration.password {
                        cell.valueLabel.font = UIFont(name: "Menlo-Regular", size: cellConfiguration.size)

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

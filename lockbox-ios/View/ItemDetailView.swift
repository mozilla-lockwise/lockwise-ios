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
    let valueFontColor: UIColor

    init(title: String, value: String, password: Bool, size: CGFloat, valueFontColor: UIColor = UIColor.black) {
        self.title = title
        self.value = value
        self.password = password
        self.size = size
        self.valueFontColor = valueFontColor
    }
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
    @IBOutlet weak var learnHowToEditButton: UIButton!
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
        self.view.backgroundColor = Constant.color.viewBackground
        self.setupNavigation()
        self.setupDataSource()
        self.setupDelegate()
        self.presenter?.onViewReady()
    }
}

extension ItemDetailView: ItemDetailViewProtocol {
    var learnHowToEditTapped: Observable<Void> {
        return self.learnHowToEditButton.rx.tap.asObservable()
    }

    func bind(itemDetail: Driver<[ItemDetailSectionModel]>) {
        if let dataSource = self.dataSource {
            itemDetail
                    .drive(self.tableView.rx.items(dataSource: dataSource))
                    .disposed(by: self.disposeBag)
        }
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
        let leftButton = UIButton(title: Constant.string.back, imageName: "back")
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)

        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .always
        }

        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        if let presenter = self.presenter {
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
                    cell.valueLabel.textColor = cellConfiguration.valueFontColor

                    cell.revealButton.isHidden = !cellConfiguration.password

                    if cellConfiguration.password {
                        cell.valueLabel.font = UIFont(name: "Menlo-Regular", size: cellConfiguration.size)

                        if let presenter = self.presenter {
                            cell.revealButton.rx.tap
                                    .map { _ -> Bool in
                                        cell.revealButton.isSelected = !cell.revealButton.isSelected

                                        return cell.revealButton.isSelected
                                    }
                                    .bind(to: presenter.onPasswordToggle)
                                    .disposed(by: cell.disposeBag)
                        }
                    }

                    return cell
                })
    }

    fileprivate func setupDelegate() {
        if let presenter = self.presenter {
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
}

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import CoreServices

typealias ItemDetailSectionModel = AnimatableSectionModel<Int, ItemDetailCellConfiguration>

class ItemDetailView: UIViewController {
    internal var presenter: ItemDetailPresenter?
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<ItemDetailSectionModel>?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var learnHowToEditButton: UIButton!
    @IBOutlet private weak var learnHowToEditArrow: UIImageView!

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
        self.tableView.dragDelegate = self
        self.learnHowToEditArrow.tintColor = Constant.color.lockBoxViolet
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

    var editTapped: Observable<Void> {
        return (self.navigationItem.rightBarButtonItem!.customView as? UIButton)!.rx.tap.asObservable()
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

    func enableBackButton(enabled: Bool) {
        if enabled {
            let leftButton = UIButton(title: Constant.string.back, imageName: "back")
            leftButton.titleLabel?.font = .navigationButtonFont
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)

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
        } else {
            self.navigationItem.leftBarButtonItem = nil
        }
    }
}

// view styling
extension ItemDetailView: UIGestureRecognizerDelegate {
    fileprivate func setupNavigation() {
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.navigationTitleFont
        ]

        let rightButton = UIButton(title: Constant.string.edit, imageName: nil)
        rightButton.titleLabel?.font = .navigationButtonFont
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
    }

    fileprivate func setupDataSource() {
        self.dataSource = RxTableViewSectionedReloadDataSource<ItemDetailSectionModel>(
                configureCell: { _, tableView, _, cellConfiguration in
                    guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemdetailcell") as? ItemDetailCell else {
                        fatalError("couldn't find the right cell!")
                    }

                    cell.titleLabel.text = cellConfiguration.title
                    cell.valueLabel.text = cellConfiguration.value

                    cell.valueLabel.textColor = cellConfiguration.valueFontColor

                    cell.accessibilityLabel = cellConfiguration.accessibilityLabel
                    cell.accessibilityIdentifier = cellConfiguration.accessibilityId

                    cell.revealButton.isHidden = cellConfiguration.revealPasswordObserver == nil
                    cell.openButton.isHidden = !cellConfiguration.showOpenButton
                    cell.copyButton.isHidden = !cellConfiguration.showCopyButton

                    cell.dragValue = cellConfiguration.dragValue

                    if let revealObserver = cellConfiguration.revealPasswordObserver {
                        cell.valueLabel.font = UIFont(name: "Menlo-Regular", size: 16)
                        cell.valueLabel.preferredMaxLayoutWidth = 250

                        cell.revealButton.rx.tap
                                .map { _ -> Bool in
                                    cell.revealButton.isSelected = !cell.revealButton.isSelected

                                    return cell.revealButton.isSelected
                                }
                                .bind(to: revealObserver)
                                .disposed(by: cell.disposeBag)
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

extension ItemDetailView: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let cell = tableView.cellForRow(at: indexPath) as? ItemDetailCell
        guard let data = cell?.dragValue as NSString? else { return [] }

        self.presenter?.dndStarted(value: cell?.titleLabel.text)

        let itemProvider = NSItemProvider(object: data as NSString)
        return [
            UIDragItem(itemProvider: itemProvider)
        ]
    }
}

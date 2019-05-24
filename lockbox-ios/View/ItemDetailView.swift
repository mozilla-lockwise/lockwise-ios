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
    private var swipeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<ItemDetailSectionModel>?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var deleteButton: UIButton!

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
        self.navigationItem.largeTitleDisplayMode = .always
        self.setupDeleteButton()
        self.setupNavigation()
        self.setupDataSource()
        self.presenter?.onViewReady()
    }
}

extension ItemDetailView: ItemDetailViewProtocol {
    var cellTapped: Observable<String?> {
        return self.tableView.rx.itemSelected
                .map { path -> String? in
                    guard let selectedCell = self.tableView.cellForRow(at: path) as? ItemDetailCell else {
                        return nil
                    }

                    return selectedCell.title.text
                }
    }

    var deleteTapped: Observable<Void> {
        return self.deleteButton.rx.tap.asObservable()
    }

    var leftBarButtonTapped: Observable<Void> {
        // swiftlint:disable:next force_cast
        return (self.navigationItem.leftBarButtonItem?.customView as! UIButton).rx.tap.asObservable()
    }

    var rightBarButtonTapped: Observable<Void> {
        // swiftlint:disable:next force_cast
        return (self.navigationItem.rightBarButtonItem?.customView as! UIButton).rx.tap.asObservable()
    }

    var itemDetailObserver: ItemDetailSectionModelObserver {
        return self.tableView.rx.items(dataSource: self.dataSource!)
    }

    var titleText: AnyObserver<String?> {
        return self.navigationItem.rx.title.asObserver()
    }

    var rightButtonText: AnyObserver<String?> {
        // swiftlint:disable:next force_cast
        return (self.navigationItem.rightBarButtonItem!.customView as! UIButton).rx.title().asObserver()
    }

    var leftButtonText: AnyObserver<String?> {
        // swiftlint:disable:next force_cast
        return (self.navigationItem.leftBarButtonItem!.customView as! UIButton).rx.title().asObserver()
    }

    var deleteHidden: AnyObserver<Bool> {
        return self.deleteButton.rx.isHidden.asObserver()
    }

    func enableLargeTitle(enabled: Bool) {
        self.navigationItem.largeTitleDisplayMode = enabled ? .always : .never
    }

    func enableSwipeNavigation(enabled: Bool) {
        if enabled {
            self.navigationController?.interactivePopGestureRecognizer?.delegate = self
            self.navigationController?.interactivePopGestureRecognizer?.rx.event
                    .map { _ -> Void in
                        return ()
                    }
                    .bind(to: self.presenter!.onRightSwipe)
                    .disposed(by: self.swipeBag)
        } else {
            self.swipeBag = DisposeBag()
        }
    }
}

// view styling
extension ItemDetailView: UIGestureRecognizerDelegate {
    fileprivate func setupDeleteButton() {
        self.deleteButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.deleteButton.titleLabel?.textAlignment = .center
        self.deleteButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        self.deleteButton.setBorder(color: Constant.color.cellBorderGrey, width: 0.5)
    }

    fileprivate func setupNavigation() {
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.navigationTitleFont
        ]

        let leftButton = UIButton(title: Constant.string.back, imageName: "back")
        leftButton.titleLabel?.font = .navigationButtonFont
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)

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

                    cell.title.text = cellConfiguration.title

                    cellConfiguration.value
                            .drive(cell.textValue.rx.text)
                            .disposed(by: cell.disposeBag)

                    cell.textValue.textColor = cellConfiguration.valueFontColor

                    cell.accessibilityLabel = cellConfiguration.accessibilityLabel
                    cell.accessibilityIdentifier = cellConfiguration.accessibilityId

                    cell.revealButton.isHidden = cellConfiguration.revealPasswordObserver == nil

                    cellConfiguration.textFieldEnabled
                            .drive(cell.textValue.rx.isUserInteractionEnabled)
                            .disposed(by: cell.disposeBag)

                    cellConfiguration.copyButtonHidden
                            .drive(cell.copyButton.rx.isHidden)
                            .disposed(by: cell.disposeBag)

                    cellConfiguration.openButtonHidden
                            .drive(cell.openButton.rx.isHidden)
                            .disposed(by: cell.disposeBag)

                    cell.dragValue = cellConfiguration.dragValue

                    if let revealObserver = cellConfiguration.revealPasswordObserver {
                        cell.textValue.font = UIFont(name: "Menlo-Regular", size: 16)

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
}

extension ItemDetailView: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let cell = tableView.cellForRow(at: indexPath) as? ItemDetailCell
        guard let data = cell?.dragValue as NSString? else {
            return []
        }

        self.presenter?.dndStarted(value: cell?.title.text)

        let itemProvider = NSItemProvider(object: data as NSString)
        return [
            UIDragItem(itemProvider: itemProvider)
        ]
    }
}

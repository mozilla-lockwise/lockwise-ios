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
        view.backgroundColor = Constant.color.viewBackground
        tableView.dragDelegate = self
        navigationItem.largeTitleDisplayMode = .always
        setupDeleteButton()
        setupNavigation()
        setupDataSource()
        presenter?.onViewReady()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenter?.onViewDisappear()
    }
}

extension ItemDetailView: ItemDetailViewProtocol {
    var cellTapped: Observable<String?> {
        return tableView.rx.itemSelected
            .map { path -> String? in
                guard let selectedCell = self.tableView.cellForRow(at: path) as? ItemDetailCell else {
                    return nil
                }
                
                return selectedCell.title.text
        }
    }

    var deleteTapped: Observable<Void> {
        return deleteButton.rx.tap.asObservable()
    }

    var leftBarButtonTapped: Observable<Void> {
        // swiftlint:disable:next force_cast
        return (navigationItem.leftBarButtonItem?.customView as! UIButton).rx.tap.asObservable()
    }

    var rightBarButtonTapped: Observable<Void> {
        // swiftlint:disable:next force_cast
        return (navigationItem.rightBarButtonItem?.customView as! UIButton).rx.tap.asObservable()
    }

    var itemDetailObserver: ItemDetailSectionModelObserver {
        return tableView.rx.items(dataSource: self.dataSource!)
    }

    var titleText: AnyObserver<String?> {
        return navigationItem.rx.title.asObserver()
    }

    var rightButtonText: AnyObserver<String?> {
        return AnyObserver<String?> { evt in
            // swiftlint:disable:next force_cast
            let button = (self.navigationItem.rightBarButtonItem!.customView as! UIButton)
            button.setTitle(evt.element ?? "", for: UIControl.State.normal)
            button.sizeToFit()

        }
    }

    var leftButtonText: AnyObserver<String?> {
        // swiftlint:disable:next force_cast
        return (navigationItem.leftBarButtonItem!.customView as! UIButton).rx.title().asObserver()
    }

    var leftButtonIcon: AnyObserver<UIImage?> {
        // swiftlint:disable:next force_cast
        return (navigationItem.leftBarButtonItem!.customView as! UIButton).rx.image().asObserver()
    }

    var deleteHidden: AnyObserver<Bool> {
        return deleteButton.rx.isHidden.asObserver()
    }

    func enableLargeTitle(enabled: Bool) {
        navigationItem.largeTitleDisplayMode = enabled ? .always : .never
    }

    func enableSwipeNavigation(enabled: Bool) {
        if enabled {
            navigationController?.interactivePopGestureRecognizer?.delegate = self
            navigationController?.interactivePopGestureRecognizer?.rx.event
                    .map { _ -> Void in
                        return ()
                    }
                    .bind(to: self.presenter!.onRightSwipe)
                    .disposed(by: self.swipeBag)
        } else {
            navigationController?.interactivePopGestureRecognizer?.delegate = nil
            swipeBag = DisposeBag()
        }
    }
}

// view styling
extension ItemDetailView: UIGestureRecognizerDelegate {
    fileprivate func setupDeleteButton() {
        deleteButton.titleLabel?.adjustsFontForContentSizeCategory = true
        deleteButton.titleLabel?.textAlignment = .center
        deleteButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        deleteButton.setBorder(color: Constant.color.cellBorderGrey, width: 0.5)
    }

    fileprivate func setupNavigation() {
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.navigationTitleFont
        ]

        let leftButton = UIButton(title: Constant.string.back, imageName: "back")
        leftButton.titleLabel?.font = .navigationButtonFont
        leftButton.accessibilityIdentifier = "backEditView.button"
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)

        // Only allow edit functionality on debug builds
        if FeatureFlags.crudEdit {
            let rightButton = UIButton(title: Constant.string.edit, imageName: nil)
            rightButton.titleLabel?.font = .navigationButtonFont
            rightButton.accessibilityIdentifier = "rightEditView.button"
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        }
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.iosThirteenNavBarAppearance()
    }

    fileprivate func setupDataSource() {
        dataSource = RxTableViewSectionedReloadDataSource<ItemDetailSectionModel>(
            configureCell: { _, tableView, _, cellConfiguration in
                guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemdetailcell") as? ItemDetailCell else {
                    fatalError("couldn't find the right cell!")
                }
                
                // Issue #1151
                cell.title.text = cellConfiguration.title
                if (cellConfiguration.title == Constant.string.webAddress) {
                    cell.textValue.isEnabled = false
                }
                
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
                
                if let textObserver = cellConfiguration.textObserver {
                    cell.textValue.rx.text.bind(to: textObserver)
                        .disposed(by: cell.disposeBag)
                }
                
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

        presenter?.dndStarted(value: cell?.title.text)

        let itemProvider = NSItemProvider(object: data as NSString)
        return [
            UIDragItem(itemProvider: itemProvider)
        ]
    }
}

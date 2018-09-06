/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

typealias ItemSectionModel = AnimatableSectionModel<Int, LoginListCellConfiguration>

enum LoginListCellConfiguration {
    case Search(enabled: Observable<Bool>, cancelHidden: Observable<Bool>, text: Observable<String>)
    case Item(title: String, username: String, guid: String)
    case SyncListPlaceholder
    case EmptyListPlaceholder(learnMoreObserver: AnyObserver<Void>)
    case NoResults(learnMoreObserver: AnyObserver<Void>)
}

extension LoginListCellConfiguration: IdentifiableType {
    var identity: String {
        switch self {
        case .Search:
            return "search"
        case .Item(_, _, let guid):
            return guid
        case .SyncListPlaceholder:
            return "syncplaceholder"
        case .EmptyListPlaceholder:
            return "emptyplaceholder"
        case .NoResults:
            return "noresultsplaceholder"
        }
    }
}

extension LoginListCellConfiguration: Equatable {
    static func ==(lhs: LoginListCellConfiguration, rhs: LoginListCellConfiguration) -> Bool {
        switch (lhs, rhs) {
        case (.Search, .Search): return true
        case (.Item(let lhTitle, let lhUsername, _), .Item(let rhTitle, let rhUsername, _)):
            return lhTitle == rhTitle && lhUsername == rhUsername
        case (.SyncListPlaceholder, .SyncListPlaceholder): return true
        case (.EmptyListPlaceholder, .EmptyListPlaceholder): return true
        case (.NoResults, .NoResults): return true
        default:
            return false
        }
    }
}

class BaseItemListView: UIViewController {
    internal var basePresenter: BaseItemListPresenter?
    @IBOutlet weak var tableView: UITableView!
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedAnimatedDataSource<ItemSectionModel>?

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.basePresenter = self.createPresenter()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Constant.color.viewBackground
        self.setNeedsStatusBarAppearanceUpdate()
        self.styleTableViewBackground()
        self.styleNavigationBar()
        self.setupDataSource()
        self.setupDelegate()
    }

    internal func createPresenter() -> BaseItemListPresenter {
        fatalError("Unimplemented")
    }

    internal func styleNavigationBar() {
        self.navigationController?.navigationBar.tintColor = UIColor.white

        self.navigationItem.title = Constant.string.yourLockbox
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.accessibilityIdentifier = "firefoxLockbox.navigationBar"
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.navigationTitleFont
        ]

        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }
    }
}

extension BaseItemListView: BaseItemListViewProtocol {
    var sortingButtonHidden: AnyObserver<Bool>? {
        if let button = self.navigationItem.leftBarButtonItem?.customView as? UIButton {
            return button.rx.isHidden.asObserver()
        } else {
            return nil
        }
    }

    func bind(items: Driver<[ItemSectionModel]>) {
        if let dataSource = self.dataSource {
            items.drive(self.tableView.rx.items(dataSource: dataSource)).disposed(by: self.disposeBag)
        }
    }

    func dismissKeyboard() {
        if let cell = self.getFilterCell() {
            cell.filterTextField.resignFirstResponder()
        }
    }

    private func getFilterCell() -> FilterCell? {
        return self.tableView.cellForRow(at: [0, 0]) as? FilterCell
    }
}

extension BaseItemListView {
    fileprivate func setupDataSource() {
        self.dataSource = RxTableViewSectionedAnimatedDataSource<ItemSectionModel>(
                configureCell: { dataSource, tableView, path, _ in
                    let cellConfiguration = dataSource[path]

                    var retCell: UITableViewCell
                    switch cellConfiguration {
                    case .Search(let enabled, let cancelHidden, let text):
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: "filtercell") as? FilterCell,
                              let presenter = self.basePresenter else {
                            fatalError("couldn't find the right cell or presenter!")
                        }
                        enabled
                                .bind(to: cell.rx.isUserInteractionEnabled)
                                .disposed(by: cell.disposeBag)

                        cell.filterTextField.rx.text
                                .orEmpty
                                .asObservable()
                                .bind(to: presenter.filterTextObserver)
                                .disposed(by: cell.disposeBag)

                        self.configureFilterCell(
                                cell,
                                presenter: presenter,
                                enabled: enabled,
                                cancelHidden: cancelHidden,
                                text: text
                        )

                        retCell = cell
                    case .Item(let title, let username, _):
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemlistcell") as? ItemListCell else {
                            fatalError("couldn't find the right cell!")
                        }

                        cell.titleLabel.text = title
                        cell.detailLabel.text = username

                        retCell = cell
                    case .SyncListPlaceholder:
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: "itemlistplaceholder") else {
                            fatalError("couldn't find the right cell!")
                        }

                        retCell = cell
                    case .EmptyListPlaceholder(let learnMoreObserver):
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: "emptylistplaceholder") as? EmptyPlaceholderCell else { // swiftlint:disable:this line_length
                            fatalError("couldn't find the right cell!")
                        }

                        cell.learnMoreButton.rx.tap
                                .bind(to: learnMoreObserver)
                                .disposed(by: cell.disposeBag)

                        retCell = cell
                    case .NoResults(let learnMoreObserver):
                        guard let cell = tableView.dequeueReusableCell(withIdentifier: "noresultsplaceholder") as? NoResultsCell else {
                            fatalError("couldn't find the no results cell")
                        }

                        cell.learnMoreButton.rx.tap
                            .bind(to: learnMoreObserver)
                            .disposed(by: cell.disposeBag)

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
        if let presenter = self.basePresenter {
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
}

// view styling
extension BaseItemListView {
    fileprivate func styleTableViewBackground() {
        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.backgroundColor = Constant.color.viewBackground
        self.tableView.backgroundView = backgroundView
    }

    fileprivate func configureFilterCell(_ cell: FilterCell,
                                         presenter: BaseItemListPresenter,
                                         enabled: Observable<Bool>,
                                         cancelHidden: Observable<Bool>,
                                         text: Observable<String>) {
        let searchImage = UIImage(named: "search")
        let searchImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40.0, height: cell.frame.height))
        searchImageView.contentMode = .center
        searchImageView.image = searchImage

        cell.filterTextField.leftView = searchImageView
        cell.filterTextField.leftViewMode = .always

        cell.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: "Edit text", target: self, selector: #selector(editFilterCell)),
            UIAccessibilityCustomAction(name: Constant.string.cancel, target: self, selector: #selector(accessibleCancel))
        ]

        enabled
                .bind(to: cell.rx.isUserInteractionEnabled)
                .disposed(by: cell.disposeBag)

        cell.filterTextField.rx.text
                .orEmpty
                .asObservable()
                .bind(to: presenter.filterTextObserver)
                .disposed(by: cell.disposeBag)

        cell.cancelButton.rx.tap
                .bind(to: presenter.filterCancelObserver)
                .disposed(by: cell.disposeBag)

        cell.filterTextField.rx.controlEvent(.editingDidEnd)
                .bind(to: presenter.editEndedObserver)
                .disposed(by: cell.disposeBag)

        cancelHidden
                .bind(to: cell.cancelButton.rx.isHidden)
                .disposed(by: cell.disposeBag)

        cancelHidden
                .subscribe(onNext: { _ in
                    UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: nil)
                })
                .disposed(by: cell.disposeBag)

        text
                .bind(to: cell.filterTextField.rx.text)
                .disposed(by: cell.disposeBag)

        let borderView = UIView()
        borderView.frame = CGRect(x: 0, y: 0, width: 1, height: cell.frame.height)
        borderView.backgroundColor = Constant.color.cellBorderGrey
        cell.cancelButton.addSubview(borderView)
    }

    @objc internal func accessibleCancel() {
        self.basePresenter?.filterCancelObserver.onNext(())
    }

    @objc internal func editFilterCell() {
        if let cell = self.getFilterCell() {
            cell.filterTextField.becomeFirstResponder()
        }
    }
}

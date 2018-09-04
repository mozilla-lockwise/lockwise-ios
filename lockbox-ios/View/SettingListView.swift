/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

typealias SettingSectionModel = AnimatableSectionModel<Int, SettingCellConfiguration>

class SettingListView: UIViewController {
    var presenter: SettingListPresenter?
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<SettingSectionModel>?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lockNowButton: UIButton!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = Constant.color.viewBackground
        self.setupDataSource()
        self.setupDelegate()
        self.setupLockNowButton()
        self.presenter?.onViewReady()

        // Subscribe to Dynamic Type change events.
        NotificationCenter.default.rx
            .notification(NSNotification.Name.UIContentSizeCategoryDidChange)
            .subscribe(onNext: { _ in self.tableView.tableFooterView?.setNeedsLayout() })
            .disposed(by: self.disposeBag)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.sizeFooterView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavbar()
        self.styleTableViewBackground()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = SettingListPresenter(view: self)
    }
}

extension SettingListView: SettingListViewProtocol {
    public var onLockNow: ControlEvent<Void> {
        return self.lockNowButton.rx.tap
    }

    func bind(items: Driver<[SettingSectionModel]>) {
        if let dataSource = self.dataSource {
            items.drive(self.tableView.rx.items(dataSource: dataSource))
                    .disposed(by: self.disposeBag)
        }
    }
}

extension SettingListView {
    private func setupDataSource() {
        self.dataSource = RxTableViewSectionedReloadDataSource(
                configureCell: { _, _, _, cellConfiguration in

                let cell = SettingCell(
                    style: cellConfiguration.cellStyle,
                    reuseIdentifier: cellConfiguration.reuseIndicator)

                cell.textLabel?.text = cellConfiguration.text
                cell.selectionStyle = UITableViewCell.SelectionStyle.none
                cell.accessibilityCustomActions = cellConfiguration.accessibilityActions
                cell.accessibilityIdentifier = cellConfiguration.accessibilityId

                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
                cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .caption2)

                if cellConfiguration.subtitle != nil {
                    cell.detailTextLabel?.attributedText = cellConfiguration.subtitle
                    cell.detailTextLabel?.numberOfLines = 0
                } else if cellConfiguration.detailText != nil {
                    cell.detailTextLabel?.text = cellConfiguration.detailText
                    cell.detailTextLabel?.font = UIFont.preferredFont(forTextStyle: .body)
                }

                if let switchSetting = cellConfiguration as? SwitchSettingCellConfiguration {
                    let switchItem = UISwitch()
                    switchItem.accessibilityIdentifier = "sendUsageData.switch"
                    switchItem.onTintColor = Constant.color.lockBoxBlue
                    switchItem.rx.value.changed.asObservable()
                        .bind(to: switchSetting.onChanged)
                        .disposed(by: cell.disposeBag)
                    switchItem.isOn = switchSetting.isOn
                    cell.accessoryView = switchItem
                } else if cellConfiguration.routeAction != nil {
                    cell.accessoryType = .disclosureIndicator
                }

                return cell
        }, titleForHeaderInSection: { _, section in
            return section == 0 ? Constant.string.settingsSupportSectionHeader :
                    Constant.string.settingsConfigurationSectionHeader
         })
    }

    private func setupDelegate() {
        if let presenter = self.presenter {
            self.tableView.rx.itemSelected
                    .map { path -> RouteAction? in
                        return self.dataSource?[path].routeAction
                    }
                    .bind(to: presenter.onSettingCellTapped)
                    .disposed(by: self.disposeBag)
        }
    }

    private func setupNavbar() {
        self.navigationItem.title = Constant.string.settingsTitle
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.navigationTitleFont
        ]
        self.navigationController?.navigationBar.accessibilityIdentifier = "settings.navigationBar"

        if #available(iOS 11.0, *) {
            self.navigationItem.largeTitleDisplayMode = .never
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Constant.string.done,
                style: .plain,
                target: nil,
                action: nil)
        navigationItem.rightBarButtonItem?.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.navigationButtonFont
        ], for: .normal)

        if let presenter = presenter {
            navigationItem.rightBarButtonItem?.rx.tap
                    .bind(to: presenter.onDone)
                    .disposed(by: self.disposeBag)
        }
    }

    fileprivate func setupLockNowButton() {
        self.lockNowButton.titleLabel?.adjustsFontForContentSizeCategory = true
        self.lockNowButton.titleLabel?.textAlignment = .center
        self.lockNowButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .body)
        self.lockNowButton.setBorder(color: Constant.color.cellBorderGrey, width: 0.5)
    }

    fileprivate func styleTableViewBackground() {
        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.backgroundColor = Constant.color.viewBackground
        self.tableView.backgroundView = backgroundView
    }

    /** Force table view footer resize.
     *
     * Footer view is not automatically resized by the table view. The method manually sizes the view and forces re-layout.
     */
    private func sizeFooterView() {
        guard let footerView = self.tableView.tableFooterView else {
            return
        }
        // Mark lockNow button for resize. Otherwise, while the container would have enough space, the text would still be truncated.
        self.lockNowButton.setNeedsLayout()

        let height = footerView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        var frame = footerView.frame
        frame.size.height = height
        footerView.frame = frame

        self.tableView.tableFooterView = footerView
    }
}

class SettingCellConfiguration {
    var text: String
    var routeAction: RouteAction?
    var enabled: Bool = true
    var detailText: String?
    var subtitle: NSAttributedString?
    var accessibilityActions: [UIAccessibilityCustomAction]?
    var accessibilityId: String

    init(text: String, routeAction: RouteAction?, accessibilityId: String) {
        self.text = text
        self.routeAction = routeAction
        self.accessibilityId = accessibilityId
    }

    var reuseIndicator: String {
        return "\(self.cellStyle.rawValue)-setting-cell"
    }

    var cellStyle: UITableViewCell.CellStyle {
        if self.subtitle != nil {
            return UITableViewCell.CellStyle.subtitle
        }

        return UITableViewCell.CellStyle.value1
    }
}

extension SettingCellConfiguration: IdentifiableType {
    var identity: String {
        return self.text
    }
}

extension SettingCellConfiguration: Equatable {
    static func ==(lhs: SettingCellConfiguration, rhs: SettingCellConfiguration) -> Bool {
        return lhs.text == rhs.text
    }
}

class SwitchSettingCellConfiguration: SettingCellConfiguration {
    var isOn: Bool = false

    var onChanged: AnyObserver<Bool>
    init(text: String, routeAction: RouteAction?, accessibilityId: String, isOn: Bool = false, onChanged: AnyObserver<Bool>) {
        self.isOn = isOn
        self.onChanged = onChanged
        super.init(text: text, routeAction: routeAction, accessibilityId: accessibilityId)
    }
}

class CheckmarkSettingCellConfiguration: SettingCellConfiguration {
    var isChecked: Bool = false
    var valueWhenChecked: Any?

    init(text: String, isChecked: Bool = false, valueWhenChecked: Any?) {
        super.init(text: text, routeAction: nil, accessibilityId: "")
        self.isChecked = isChecked
        self.valueWhenChecked = valueWhenChecked
    }
}

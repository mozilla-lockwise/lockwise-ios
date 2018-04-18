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
    @IBOutlet weak var signOutButton: UIButton!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDataSource()
        self.setupDelegate()
        self.setupSignOutButton()
        self.presenter?.onViewReady()
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
    public var onSignOut: ControlEvent<Void> {
        return self.signOutButton.rx.tap
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
                cell.selectionStyle = UITableViewCellSelectionStyle.none

                if cellConfiguration.subtitle != nil {
                    cell.detailTextLabel?.attributedText = cellConfiguration.subtitle
                    cell.detailTextLabel?.numberOfLines = 0
                } else if cellConfiguration.detailText != nil {
                    cell.detailTextLabel?.text = cellConfiguration.detailText
                }

                if let switchSetting = cellConfiguration as? SwitchSettingCellConfiguration {
                    let switchItem = UISwitch()
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
            return section == 0 ? Constant.string.settingsHelpSectionHeader :
                    Constant.string.settingsConfigurationSectionHeader
         })
    }

    private func setupDelegate() {
        if let presenter = self.presenter {
            self.tableView.rx.itemSelected
                    .map { path -> SettingRouteAction? in
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
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: Constant.string.done,
                style: .done,
                target: nil,
                action: nil)
        navigationItem.rightBarButtonItem?.tintColor = UIColor.white

        if let presenter = presenter {
            navigationItem.rightBarButtonItem?.rx.tap
                    .bind(to: presenter.onDone)
                    .disposed(by: self.disposeBag)
        }
    }

    fileprivate func setupSignOutButton() {
        self.signOutButton.addTopBorderWithColor(color: Constant.color.cellBorderGrey, width: 0.5)
        self.signOutButton.addBottomBorderWithColor(color: Constant.color.cellBorderGrey, width: 0.5)
    }

    fileprivate func styleTableViewBackground() {
        let backgroundView = UIView(frame: self.view.bounds)
        backgroundView.backgroundColor = Constant.color.viewBackground
        self.tableView.backgroundView = backgroundView
    }
}

class SettingCellConfiguration {
    var text: String
    var routeAction: SettingRouteAction?
    var enabled: Bool = true
    var detailText: String?
    var subtitle: NSAttributedString?

    init(text: String, routeAction: SettingRouteAction?) {
        self.text = text
        self.routeAction = routeAction
    }

    var reuseIndicator: String {
        return "\(self.cellStyle.rawValue)-setting-cell"
    }

    var cellStyle: UITableViewCellStyle {
        if self.subtitle != nil {
            return UITableViewCellStyle.subtitle
        }

        return UITableViewCellStyle.value1
    }
}

extension SettingCellConfiguration: IdentifiableType {
    var identity: String {
        return self.text
    }
}

extension SettingCellConfiguration: Equatable {
    static func ==(lhs: SettingCellConfiguration, rhs: SettingCellConfiguration) -> Bool {
        return lhs.text == rhs.text && lhs.routeAction == rhs.routeAction
    }
}

class SwitchSettingCellConfiguration: SettingCellConfiguration {
    var isOn: Bool = false

    var onChanged: AnyObserver<Bool>
    init(text: String, routeAction: SettingRouteAction?, isOn: Bool = false, onChanged: AnyObserver<Bool>) {
        self.isOn = isOn
        self.onChanged = onChanged
        super.init(text: text, routeAction: routeAction)
    }
}

class CheckmarkSettingCellConfiguration: SettingCellConfiguration {
    var isChecked: Bool = false
    var valueWhenChecked: Any?

    init(text: String, isChecked: Bool = false, valueWhenChecked: Any?) {
        super.init(text: text, routeAction: nil)
        self.isChecked = isChecked
        self.valueWhenChecked = valueWhenChecked
    }
}

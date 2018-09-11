/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import RxSwift
import RxCocoa
import RxDataSources

typealias PreferredBrowserSettingSectionModel = AnimatableSectionModel<Int, CheckmarkSettingCellConfiguration>

class PreferredBrowserSettingView: UITableViewController {
    var presenter: PreferredBrowserSettingPresenter?
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<PreferredBrowserSettingSectionModel>?

    init() {
        super.init(style: UITableView.Style.grouped)
        self.presenter = PreferredBrowserSettingPresenter(view: self)
        view.backgroundColor = Constant.color.viewBackground
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setupNavbar()
        self.setupFooter()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupDataSource()
        self.setupDelegate()
        self.presenter?.onViewReady()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UITableViewCell()
    }
}

extension PreferredBrowserSettingView {
    private func setupFooter() {
        self.tableView.tableFooterView = UIView()
    }

    private func setupDataSource() {
        self.dataSource = RxTableViewSectionedReloadDataSource(
            configureCell: {(_, _, _, cellConfiguration) -> UITableViewCell in
                let cell = SettingCell()
                cell.textLabel?.text = cellConfiguration.text
                cell.textLabel?.font = UIFont.preferredFont(forTextStyle: .body)
                cell.accessoryType = cellConfiguration.isChecked ?
                    UITableViewCell.AccessoryType.checkmark : UITableViewCell.AccessoryType.none
                cell.selectionStyle = UITableViewCell.SelectionStyle.none

                if !cellConfiguration.enabled {
                    cell.isUserInteractionEnabled = false
                    cell.textLabel?.isEnabled = false
                    cell.accessibilityLabel = String(
                            format: Constant.string.installBrowserAccessibilityLabel,
                            cellConfiguration.text
                    )
                }

                return cell
        })
    }

    private func setupDelegate() {
        if let presenter = self.presenter {
            self.tableView.rx.itemSelected
                .map { (indexPath) -> Setting.PreferredBrowser? in
                    self.tableView.deselectRow(at: indexPath, animated: true)
                    return self.dataSource?[indexPath].valueWhenChecked as? Setting.PreferredBrowser
                }.bind(to: presenter.itemSelectedObserver)
                .disposed(by: self.disposeBag)
        }
    }
}

extension PreferredBrowserSettingView: PreferredBrowserSettingViewProtocol {
    func bind(items: SharedSequence<DriverSharingStrategy, [PreferredBrowserSettingSectionModel]>) {
        if let dataSource = dataSource {
            items
                .drive(self.tableView.rx.items(dataSource: dataSource))
                .disposed(by: self.disposeBag)
        }
    }
}

extension PreferredBrowserSettingView: UIGestureRecognizerDelegate {
    private func setupNavbar() {
        self.navigationItem.title = Constant.string.settingsBrowser
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.navigationTitleFont
        ]
        self.navigationController?.navigationBar.accessibilityIdentifier = "openWebSitesIn.navigationBar"
        let leftButton = UIButton(title: Constant.string.settingsTitle, imageName: "back")
        leftButton.titleLabel?.font = .navigationButtonFont
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)

        if let presenter = self.presenter {
            leftButton.rx.tap
                .bind(to: presenter.onSettingsTap)
                .disposed(by: self.disposeBag)

            self.navigationController?.interactivePopGestureRecognizer?.delegate = self
            self.navigationController?.interactivePopGestureRecognizer?.rx.event
                .map { _ -> Void in
                    return ()
                }
                .bind(to: presenter.onSettingsTap)
                .disposed(by: self.disposeBag)
        }
    }
}

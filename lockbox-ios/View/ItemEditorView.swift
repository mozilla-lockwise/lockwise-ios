/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class ItemEditorView: UIViewController {
    internal var presenter: ItemEditorPresenter?
    private var disposeBag = DisposeBag()
    private var dataSource: RxTableViewSectionedReloadDataSource<ItemDetailSectionModel>?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var deleteButton: UIButton!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = ItemEditorPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupNavigation()
        self.setupDataSource()
        self.presenter?.onViewReady()
    }
}

extension ItemEditorView: ItemEditorViewProtocol {
    var deleteTapped: Observable<Void> {
        return self.deleteButton.rx.tap.asObservable()
    }

    var saveTapped: Observable<Void> {
        return self.navigationItem.rightBarButtonItem!.rx.tap.asObservable()
    }

    var cancelTapped: Observable<Void> {
        return self.navigationItem.leftBarButtonItem!.rx.tap.asObservable()
    }

    func bind(itemDetail: Driver<[ItemDetailSectionModel]>) {

    }
}

extension ItemEditorView: UIGestureRecognizerDelegate {
    fileprivate func setupNavigation() {
        self.navigationController?.navigationBar.tintColor = .white
        self.navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.navigationTitleFont
        ]
        self.navigationItem.largeTitleDisplayMode = .never

        let leftButton = UIButton(title: Constant.string.cancel, imageName: nil)
        leftButton.titleLabel?.font = .navigationButtonFont
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: leftButton)

        let rightButton = UIButton(title: Constant.string.save, imageName: nil)
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
}

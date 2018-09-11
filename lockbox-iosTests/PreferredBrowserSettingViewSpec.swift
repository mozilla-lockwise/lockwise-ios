/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxTest
import RxSwift
import RxCocoa

@testable import Lockbox

class PreferredBrowserSettingViewSpec: QuickSpec {
    class FakePreferredBrowserSettingPresenter: PreferredBrowserSettingPresenter {
        var onViewReadyCalled = false
        var onItemSelectedActionDispatched = false

        override func onViewReady() {
            self.onViewReadyCalled = true
        }

        override var itemSelectedObserver: AnyObserver<Setting.PreferredBrowser?> {
            return Binder(self) { target, _ in
                target.onItemSelectedActionDispatched = true
                }.asObserver()
        }
    }

    var presenter: FakePreferredBrowserSettingPresenter!
    var subject: PreferredBrowserSettingView!

    override func spec() {
        beforeEach {
            self.subject = PreferredBrowserSettingView()
            self.presenter = FakePreferredBrowserSettingPresenter(view: self.subject)
            self.subject.presenter = self.presenter
            self.subject.viewWillAppear(false)
            self.subject.viewDidLoad()
        }

        it("informs the presenter") {
            expect(self.presenter.onViewReadyCalled).to(beTrue())
        }

        it("sets the title") {
            expect(self.subject.navigationItem.title).to(equal(Constant.string.settingsBrowser ))
        }

        describe("tableview datasource configuration") {
            let configDriver = PublishSubject<[PreferredBrowserSettingSectionModel]>()

            let sectionModels = [PreferredBrowserSettingSectionModel(model: 0, items: [
                CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserFirefox, isChecked: false, valueWhenChecked: Setting.PreferredBrowser.Firefox),
                CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserSafari, isChecked: true, valueWhenChecked: Setting.PreferredBrowser.Safari),
                CheckmarkSettingCellConfiguration(text: Constant.string.settingsBrowserFocus, isChecked: false, valueWhenChecked: Setting.PreferredBrowser.Focus)
                ])]

            sectionModels[0].items[2].enabled = false

            beforeEach {
                self.subject.bind(items: configDriver.asDriver(onErrorJustReturn: []))
                configDriver.onNext(sectionModels)
                (self.subject.tableView.delegate!).tableView!(self.subject.tableView, didSelectRowAt: [0, 0])
            }

            it("configures table view based on model") {
                expect(self.subject.tableView.numberOfSections).to(equal(1))
                expect(self.subject.tableView.numberOfRows(inSection: 0)).to(equal(3))
                expect(self.subject.tableView.cellForRow(at: IndexPath(row: 1, section: 0))?.accessoryType).to(equal(UITableViewCell.AccessoryType.checkmark))
                expect(self.subject.tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.accessoryType).to(equal(UITableViewCell.AccessoryType.none))
                expect(self.subject.tableView.cellForRow(at: IndexPath(row: 2, section: 0))?.accessoryType).to(equal(UITableViewCell.AccessoryType.none))
                expect(self.subject.tableView.cellForRow(at: IndexPath(row: 2, section: 0))?.isUserInteractionEnabled).to(beFalse())
                expect(self.subject.tableView.cellForRow(at: IndexPath(row: 2, section: 0))?.textLabel?.isEnabled).to(beFalse())
            }

            it("calls presenter when cell is tapped") {
                expect(self.presenter.onItemSelectedActionDispatched).to(beTrue())
            }
        }
    }
}

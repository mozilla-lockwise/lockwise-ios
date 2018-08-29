/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import UIKit
import RxTest
import RxSwift
import RxCocoa

@testable import Lockbox

class SettingListViewSpec: QuickSpec {
    class FakeSettingsPresenter: SettingListPresenter {
        var onViewReadyCalled = false
        var onDoneActionDispatched = false
        var settingCellStub: TestableObserver<RouteAction?>!
        var usageDataCellStub: TestableObserver<Bool>!

        override func onViewReady() {
            onViewReadyCalled = true
        }

        override var onDone: AnyObserver<Void> {
            return Binder(self) { target, _ in
                target.onDoneActionDispatched = true
            }.asObserver()
        }

        override var onSettingCellTapped: AnyObserver<RouteAction?> {
            return self.settingCellStub.asObserver()
        }

        override var onUsageDataSettingChanged: AnyObserver<Bool> {
            return self.usageDataCellStub.asObserver()
        }
    }

    private var presenter: FakeSettingsPresenter!
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
    var subject: SettingListView!

    override func spec() {
        describe("SettingListView") {
            beforeEach {
                self.subject = UIStoryboard(name: "SettingList", bundle: nil).instantiateViewController(withIdentifier: "settinglist") as? SettingListView
                self.presenter = FakeSettingsPresenter(view: self.subject)
                self.presenter.settingCellStub = self.scheduler.createObserver(RouteAction?.self)
                self.presenter.usageDataCellStub = self.scheduler.createObserver(Bool.self)
                self.subject.presenter = self.presenter

                self.subject.preloadView()
            }

            it("informs the presenter") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            describe("tableview datasource configuration") {
                beforeEach {
                    let configDriver = PublishSubject<[SettingSectionModel]>()
                    let sectionModels = [
                        SettingSectionModel(model: 0, items: [
                            SettingCellConfiguration(text: "Account", routeAction: SettingRouteAction.list, accessibilityId: ""),
                            SettingCellConfiguration(text: "FAQ", routeAction: SettingRouteAction.list, accessibilityId: "")
                            ]),
                        SettingSectionModel(model: 1, items: [
                            SwitchSettingCellConfiguration(text: "Send Usage Data", routeAction: nil, accessibilityId: "", isOn: true, onChanged: self.presenter.onUsageDataSettingChanged)
                            ])
                    ]

                    sectionModels[0].items[1].detailText = "FAQ Detail"

                    self.subject.bind(items: configDriver.asDriver(onErrorJustReturn: []))
                    configDriver.onNext(sectionModels)

                    let cell = self.subject.tableView.cellForRow(at: IndexPath(item: 0, section: 1))
                    let switchControl = cell?.accessoryView as? UISwitch
                    switchControl?.isOn = false
                    switchControl?.sendActions(for: .valueChanged)
                }

                it("configures table view based on model") {
                    expect(self.subject.tableView.numberOfSections).to(equal(2))
                    expect(self.subject.tableView.numberOfRows(inSection: 0)).to(equal(2))
                    expect(self.subject.tableView.numberOfRows(inSection: 1)).to(equal(1))
                }

                it("calls presenter when usage data switch is flipped") {
                    expect(self.presenter.usageDataCellStub.events.last!.value.element).to(beFalse())
                }

                it("sets detail text") {
                    expect(self.subject.tableView.cellForRow(at: IndexPath(item: 1, section: 0))?.detailTextLabel?.text).to(equal("FAQ Detail"))
                }
            }

            describe("tableview delegate configuration") {
                beforeEach {
                    let configDriver = PublishSubject<[SettingSectionModel]>()
                    let sectionModels = [
                        SettingSectionModel(model: 0, items: [
                            SettingCellConfiguration(text: "Account", routeAction: SettingRouteAction.account, accessibilityId: ""),
                            SettingCellConfiguration(text: "FAQ", routeAction: SettingRouteAction.list, accessibilityId: "")
                            ]),
                        SettingSectionModel(model: 1, items: [
                            SwitchSettingCellConfiguration(text: "Send Usage Data", routeAction: nil, accessibilityId: "", isOn: true, onChanged: self.presenter.onUsageDataSettingChanged)
                            ])
                    ]

                    self.subject.bind(items: configDriver.asDriver(onErrorJustReturn: []))
                    configDriver.onNext(sectionModels)
                }

                describe("onCellTapped") {
                    beforeEach {
                        self.subject.tableView.delegate!.tableView!(self.subject.tableView, didSelectRowAt: [0, 0])
                    }

                    it("tells the presenter with the appropriate action") {
                        let action = self.presenter.settingCellStub.events.first!.value.element as! SettingRouteAction
                        expect(action).to(equal(SettingRouteAction.account))
                    }
                }

                describe("SettingCell") {
                    it("highlights correctly") {
                        let cell = self.subject.tableView.cellForRow(at: [0, 0])

                        cell?.setHighlighted(true, animated: false)
                        expect(cell?.backgroundColor).to(equal(Constant.color.tableViewCellHighlighted))

                        cell?.setHighlighted(false, animated: false)
                        expect(cell?.backgroundColor).to(equal(UIColor.white))
                    }

                    it("prepareForReuse changes DisposeBag") {
                        let cell = SettingCell(style: UITableViewCell.CellStyle.default, reuseIdentifier: "setting-cell")
                        let oldDisposeBag = cell.disposeBag
                        expect(cell.prepareForReuse()).toNot(be(oldDisposeBag))
                    }
                }
            }

            describe("onSignOut") {
                var observer = self.scheduler.createObserver(Void.self)

                beforeEach {
                    observer = self.scheduler.createObserver(Void.self)

                    self.subject.onSignOut.subscribe(observer).disposed(by: self.disposeBag)

                    self.subject.signOutButton.sendActions(for: .touchUpInside)
                }

                it("tells any observers") {
                    expect(observer.events.count).to(equal(1))
                }
            }
        }

        describe("SettingCellConfiguration") {
            describe("equality") {
                it("SettingCellConfigurations are equal when the text is equal") {
                    expect(SettingCellConfiguration(text: "meow", routeAction: SettingRouteAction.account, accessibilityId: "")).to(equal(SettingCellConfiguration(text: "meow", routeAction: SettingRouteAction.account, accessibilityId: "")))
                    expect(SettingCellConfiguration(text: "meow", routeAction: SettingRouteAction.account, accessibilityId: "")).notTo(equal(SettingCellConfiguration(text: "woof", routeAction: SettingRouteAction.account, accessibilityId: "")))
                    expect(SettingCellConfiguration(text: "meow", routeAction: nil, accessibilityId: "")).to(equal(SettingCellConfiguration(text: "meow", routeAction: SettingRouteAction.account, accessibilityId: "")))
                    expect(SettingCellConfiguration(text: "meow", routeAction: nil, accessibilityId: "")).notTo(equal(SettingCellConfiguration(text: "woof", routeAction: SettingRouteAction.account, accessibilityId: "")))
                }
            }
        }
    }
}

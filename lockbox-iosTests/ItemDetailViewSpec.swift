/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Quick
import Nimble
import RxSwift
import RxCocoa
import RxDataSources
import RxTest

@testable import Lockbox

class ItemDetailViewSpec: QuickSpec {

    class FakeItemDetailPresenter: ItemDetailPresenter {
        var onViewReadyCalled = false
        var onPasswordToggleActionDispatched: Bool?
        var onCancelActionDispatched = false
        var onCellTappedValue: String?

        override func onViewReady() {
            self.onViewReadyCalled = true
        }

        override var onRightSwipe: AnyObserver<Void> {
            return Binder(self) { target, _ in
                target.onCancelActionDispatched = true
            }.asObserver()
        }
        
        override var onPasswordToggle: AnyObserver<Bool> {
            return Binder(self) { target, revealed in
                target.onPasswordToggleActionDispatched = true
            }.asObserver()
        }

    }

    private var presenter: FakeItemDetailPresenter!
    private let scheduler = TestScheduler(initialClock: 0)
    private let disposeBag = DisposeBag()
    var subject: ItemDetailView!

    override func spec() {
        describe("ItemDetailView") {
            beforeEach {
                let sb = UIStoryboard(name: "ItemDetail", bundle: nil)
                self.subject = sb.instantiateViewController(withIdentifier: "itemdetailview") as? ItemDetailView
                self.presenter = FakeItemDetailPresenter(view: self.subject)

                self.subject.presenter = self.presenter

                self.subject.preloadView()
            }

            it("informs the presenter") {
                expect(self.presenter.onViewReadyCalled).to(beTrue())
            }

            describe("tableview datasource configuration") {
                var revealPasswordObserver = self.scheduler.createObserver(Bool.self)
                var usernameTextObserver = self.scheduler.createObserver(String?.self)

                beforeEach {
                    revealPasswordObserver = self.scheduler.createObserver(Bool.self)
                    usernameTextObserver = self.scheduler.createObserver(String?.self)
                    let sectionModels = [
                        ItemDetailSectionModel(model: 0, items: [
                            ItemDetailCellConfiguration(
                                    title: Constant.string.webAddress,
                                    value: Driver.just("www.meow.com"),
                                    accessibilityLabel: "something accessible",
                                    valueFontColor: Constant.color.lockBoxViolet,
                                    accessibilityId: "",
                                    textFieldEnabled: Driver.just(false))
                        ]),
                        ItemDetailSectionModel(model: 1, items: [
                            ItemDetailCellConfiguration(
                                    title: Constant.string.username,
                                    value: Driver.just("tanya"),
                                    accessibilityLabel: "something else accessible",
                                    accessibilityId: "",
                                    textFieldEnabled: Driver.just(false),
                                    textObserver: usernameTextObserver.asObserver()),
                            ItemDetailCellConfiguration(
                                    title: Constant.string.password,
                                    value: Driver.just("iluvdawgz"),
                                    accessibilityLabel: "more accessible here",
                                    valueFontColor: .black,
                                    accessibilityId: "",
                                    textFieldEnabled: Driver.just(false),
                                    revealPasswordObserver: revealPasswordObserver.asObserver())
                        ])
                    ]

                    Driver.just(sectionModels)
                            .drive(self.subject!.itemDetailObserver)
                            .disposed(by: self.disposeBag)
                }

                it("configures the tableview based on the models provided") {
                    expect(self.subject.tableView.numberOfSections).to(equal(2))
                }

                it("binds password reveal tap actions to the observer") {
                    let cell = self.subject.tableView.cellForRow(at: [1, 1]) as! ItemDetailCell
                    cell.revealButton.sendActions(for: .touchUpInside)

                    expect(revealPasswordObserver.events.count).to(equal(1))
                    expect(revealPasswordObserver.events.first?.value.element).to(beTrue())
                }

                it("binds textObserver text change actions to the observer") {
                    let cell = self.subject.tableView.cellForRow(at: [1, 0]) as! ItemDetailCell
                    cell.textValue.sendActions(for: .editingChanged)

                    expect(usernameTextObserver.events.count).to(equal(2))
                    expect(usernameTextObserver.events.first?.value.element).to(equal("tanya"))
                }

                describe("tapping cells") {
                    var cellTapObserver = self.scheduler.createObserver(String?.self)

                    beforeEach {
                        cellTapObserver = self.scheduler.createObserver(String?.self)
                        self.subject.cellTapped
                                .subscribe(cellTapObserver)
                                .disposed(by: self.disposeBag)

                        self.subject.tableView.delegate!.tableView!(self.subject.tableView, didSelectRowAt: [1, 0])
                    }

                    it("extracts the titlelabel text and tells the presenter") {
                        expect(cellTapObserver.events.count).to(equal(1))
                        expect(cellTapObserver.events.first!.value.element).to(equal(Constant.string.username))
                    }
                }

                it("sets the font color for web address") {
                    expect((self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell).textValue.textColor).to(equal(Constant.color.lockBoxViolet))
                }

                it("sets the passed accessibility label for every cell") {
                    expect(self.subject.tableView.cellForRow(at: [0, 0])?.accessibilityLabel).to(equal("something accessible"))
                }
            }

            describe("title text") {
                let title = "new title"

                beforeEach {
                    Observable.just(title)
                            .subscribe(self.subject.titleText)
                            .disposed(by: self.disposeBag)
                }

                it("updates the navigation title with new values") {
                    expect(self.subject.navigationItem.title).to(equal(title))
                }
            }

            describe("tapping left button with text set") {
                var voidObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    voidObserver = self.scheduler.createObserver(Void.self)

                    self.subject.leftButtonText.onNext("Cancel")

                    self.subject.leftBarButtonTapped
                            .bind(to: voidObserver)
                            .disposed(by: self.disposeBag)

                    let button = self.subject.navigationItem.leftBarButtonItem!.customView as! UIButton
                    _ = button.sendActions(for: .touchUpInside)
                }

                it("informs the observer") {
                    expect(voidObserver.events.count).to(equal(1))
                }
            }

            describe("tapping right button with text set") {
                var voidObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    voidObserver = self.scheduler.createObserver(Void.self)

                    self.subject.rightButtonText.onNext("Edit")

                    self.subject.rightBarButtonTapped
                            .bind(to: voidObserver)
                            .disposed(by: self.disposeBag)

                    let editButton = self.subject.navigationItem.rightBarButtonItem!.customView as! UIButton
                    editButton.sendActions(for: .touchUpInside)
                }

                it("informs any observers") {
                    expect(voidObserver.events.count).to(equal(1))
                }
            }

            describe("delete button when visible") {
                var voidObserver = self.scheduler.createObserver(Void.self)

                beforeEach {
                    voidObserver = self.scheduler.createObserver(Void.self)
                    self.subject.deleteTapped
                            .subscribe(voidObserver)
                            .disposed(by: self.disposeBag)

                    self.subject.deleteHidden.onNext(false)

                    self.subject.deleteButton.sendActions(for: .touchUpInside)
                }

                it("informs any observers") {
                    expect(voidObserver.events.count).to(equal(1))
                }
            }

            describe("enableLargeTitle") {
                it("enabled sets large title display mode") {
                    self.subject.enableLargeTitle(enabled: true)
                    expect(self.subject.navigationItem.largeTitleDisplayMode).to(equal(.always))
                }

                it("disabled sets never for large title display mode") {
                    self.subject.enableLargeTitle(enabled: false)
                    expect(self.subject.navigationItem.largeTitleDisplayMode).to(equal(.never))
                }
            }

            describe("ItemDetailCell") {
                let valueStub = PublishSubject<String>()
                let textFieldEnabledStub = PublishSubject<Bool>()
                let copyButtonHiddenStub = PublishSubject<Bool>()
                let openButtonHiddenStub = PublishSubject<Bool>()

                beforeEach {
                    let sectionModelWithJustOneItem = [
                        ItemDetailSectionModel(model: 1, items: [
                            ItemDetailCellConfiguration(
                                    title: Constant.string.password,
                                    value: valueStub.asDriver(onErrorJustReturn: ""),
                                    accessibilityLabel: "something accessible",
                                    accessibilityId: "",
                                    textFieldEnabled: textFieldEnabledStub.asDriver(onErrorJustReturn: false),
                                    copyButtonHidden: copyButtonHiddenStub.asDriver(onErrorJustReturn: false),
                                    openButtonHidden: openButtonHiddenStub.asDriver(onErrorJustReturn: false))
                        ])
                    ]

                    Driver.just(sectionModelWithJustOneItem)
                            .drive(self.subject!.itemDetailObserver)
                            .disposed(by: self.disposeBag)
                }

                it("binds the value") {
                    let cell = self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell
                    let val1 = "meow"
                    let val2 = "woof"

                    valueStub.onNext(val1)
                    expect(cell.textValue.text).to(equal(val1))

                    valueStub.onNext(val2)
                    expect(cell.textValue.text).to(equal(val2))
                }

                it("binds the textfield enabled status") {
                    let cell = self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell
                    let val1 = true
                    let val2 = false

                    textFieldEnabledStub.onNext(val1)
                    expect(cell.textValue.isUserInteractionEnabled).to(equal(val1))

                    textFieldEnabledStub.onNext(val2)
                    expect(cell.textValue.isUserInteractionEnabled).to(equal(val2))
                }

                it("binds the copy button hidden status") {
                    let cell = self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell
                    let val1 = true
                    let val2 = false

                    copyButtonHiddenStub.onNext(val1)
                    expect(cell.copyButton.isHidden).to(equal(val1))

                    copyButtonHiddenStub.onNext(val2)
                    expect(cell.copyButton.isHidden).to(equal(val2))
                }

                it("binds the open button hidden status") {
                    let cell = self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell
                    let val1 = true
                    let val2 = false

                    openButtonHiddenStub.onNext(val1)
                    expect(cell.openButton.isHidden).to(equal(val1))

                    openButtonHiddenStub.onNext(val2)
                    expect(cell.openButton.isHidden).to(equal(val2))
                }

                it("prepareForReuse disposes the cell's dispose bag") {
                    let cell = self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell

                    let disposeBag = cell.disposeBag

                    cell.prepareForReuse()

                    expect(cell.disposeBag === disposeBag).notTo(beTrue())
                }

                it("highlighting the cell changes the background color") {
                    let cell = self.subject.tableView.cellForRow(at: [0, 0]) as! ItemDetailCell

                    cell.setHighlighted(true, animated: false)
                    expect(cell.backgroundColor).to(equal(Constant.color.tableViewCellHighlighted))

                    cell.setHighlighted(false, animated: false)
                    expect(cell.backgroundColor).to(equal(UIColor.white))
                }
            }
        }
    }
}

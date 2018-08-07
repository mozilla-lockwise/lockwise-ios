/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa
import SwiftKeychainWrapper

class AutoLockStore {
    static let shared = AutoLockStore()
    private let disposeBag = DisposeBag()

    private let dispatcher: Dispatcher
    private let dataStore: DataStore
    private let userDefaults: UserDefaults
    private let keychainWrapper: KeychainWrapper

    var timer: Timer?
    var paused: Bool = false

    init(dispatcher: Dispatcher = Dispatcher.shared,
         dataStore: DataStore = DataStore.shared,
         userDefaults: UserDefaults = .standard,
         keychainWrapper: KeychainWrapper = KeychainWrapper(serviceName: "", accessGroup: Constant.app.group)
    ) {
        self.dispatcher = dispatcher
        self.userDefaults = userDefaults
        self.keychainWrapper = keychainWrapper
        self.dataStore = dataStore

        self.dataStore.locked
                .subscribe(onNext: { [weak self] locked in
                    if locked {
                        self?.stopTimer()
                    } else {
                        self?.setupTimer()
                    }
                })
                .disposed(by: self.disposeBag)

        self.dispatcher.register
                .filter { action -> Bool in
                    // future user interaction actions will need to get added to this list
                    action is MainRouteAction ||
                            action is SettingRouteAction ||
                            action is CopyAction ||
                            action is ExternalLinkAction ||
                            action is ItemListDisplayAction ||
                            action is ItemDetailDisplayAction ||
                            action is SettingAction
                }
                .subscribe(onNext: { [weak self] _ in
                    self?.resetTimer()
                })
                .disposed(by: self.disposeBag)

        self.dispatcher.register
                .filterByType(class: ExternalWebsiteRouteAction.self)
                .subscribe(onNext: { [weak self] _ in
                    self?.pauseTimer()
                })
                .disposed(by: self.disposeBag)

        self.dispatcher.register
                .filterByType(class: LifecycleAction.self)
                .filter { $0 == LifecycleAction.foreground }
                .subscribe(onNext: { [weak self] _ in
                    self?.paused = false
                    self?.setupTimer()
                })
                .disposed(by: self.disposeBag)
    }
}

extension AutoLockStore {
    private func resetTimer() {
        self.stopTimer(reset: !paused)
        self.setupTimer()
    }

    private func setupTimer() {
        self.userDefaults.onAutoLockTime
                .take(1)
                .subscribe(onNext: { (latest: Setting.AutoLock) in
                    switch latest {
                    case .Never:
                        self.stopTimer()
                    default:
                        self.setTimer(seconds: latest.seconds)
                    }
                    return
                })
                .disposed(by: self.disposeBag)
    }

    private func setTimer(seconds: Int) {
        let timerValue = self.userDefaults.double(forKey: UserDefaultKey.autoLockTimerDate.rawValue)
        if timerValue != 0 && timerValue > Date().timeIntervalSince1970 {
            self.timer = Timer(fireAt: Date(timeIntervalSince1970: timerValue),
                    interval: 0,
                    target: self,
                    selector: #selector(lockApp),
                    userInfo: nil,
                    repeats: false)
        } else if timerValue != 0 && timerValue <= Date().timeIntervalSince1970 {
            self.lockApp()
        } else {
            self.timer = Timer(timeInterval: TimeInterval(seconds),
                    target: self,
                    selector: #selector(lockApp),
                    userInfo: nil,
                    repeats: false)

            self.userDefaults.set(self.timer?.fireDate.timeIntervalSince1970,
                    forKey: UserDefaultKey.autoLockTimerDate.rawValue)
        }

        paused = false

        if let timer = self.timer {
            DispatchQueue.main.async {
                RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
            }
        }
    }

    private func pauseTimer() {
        paused = true
        self.stopTimer(reset: !paused)
    }

    private func stopTimer(reset: Bool = true) {
        if let timer = self.timer {
            timer.invalidate()
        }
        if reset {
            self.userDefaults.removeObject(forKey: UserDefaultKey.autoLockTimerDate.rawValue)
        }
    }

    @objc private func lockApp() {
        if !paused {
            self.dispatcher.dispatch(action: DataStoreAction.lock)
            self.userDefaults.removeObject(forKey: UserDefaultKey.autoLockTimerDate.rawValue)
        }
    }
}

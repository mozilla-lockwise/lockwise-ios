/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import RxSwift
import RxCocoa

class BaseAutoLockStore {
    internal let disposeBag = DisposeBag()

    internal let dispatcher: Dispatcher
    internal let dataStore: DataStore
    internal let userDefaults: UserDefaults

    var timer: Timer?
    var paused: Bool = false

    init(dispatcher: Dispatcher = Dispatcher.shared,
         dataStore: DataStore = DataStore.shared,
         userDefaults: UserDefaults = UserDefaults(suiteName: Constant.app.group) ?? .standard) {
        self.dispatcher = dispatcher
        self.userDefaults = userDefaults
        self.dataStore = dataStore

        self.initialized()
    }

    open func initialized() {
        fatalError("not implemented!")
    }
}

extension BaseAutoLockStore {
    internal func resetTimer() {
        self.stopTimer(reset: !paused)
        self.setupTimer()
    }

    internal func setupTimer() {
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
            self.userDefaults.synchronize()
        }

        paused = false

        if let timer = self.timer {
            DispatchQueue.main.async {
                RunLoop.current.add(timer, forMode: RunLoop.Mode.default)
            }
        }
    }

    internal func pauseTimer() {
        paused = true
        self.stopTimer(reset: !paused)
    }

    internal func stopTimer(reset: Bool = true) {
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

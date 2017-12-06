/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import WebKit
import Foundation
import RxSwift

class ViewController: UIViewController {
    var webView: WebView!
    var dataStore: DataStore!
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        let webConfig = WKWebViewConfiguration()
//
//        var webView:WebView = WebView(frame: .zero, configuration: webConfig)
//        self.dataStore = DataStore(webView: &webView)
//        self.webView = webView

//        self.view.addSubview(self.webView)
    }

    @IBAction func initClicked(_ sender: Any) {
        self.dataStore.initialize(password: "password")
                .subscribe(onSuccess: { any in print("initialized!") }, onError: { error in print("error") })
                .disposed(by: self.disposeBag)
    }

    @IBAction func unlockClicked(_ sender: Any) {
        self.dataStore.unlock(password: "password")
                .subscribe(onSuccess: { any in print("unlocked!") }, onError: { error in print("error") })
                .disposed(by: self.disposeBag)
    }

    @IBAction func listClicked(_ sender: Any) {
        self.dataStore.list().subscribe(onSuccess: { list in
                    for item in list {
                        print(item)
                    }
                }, onError: { error in
                    print("error: \(error)")
                })
                .disposed(by: disposeBag)
    }
}

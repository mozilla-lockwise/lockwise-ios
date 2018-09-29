/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import RxSwift
import RxCocoa
import AVKit

class AutofillInstructionsView: UIViewController {
    internal var presenter: AutofillInstructionsPresenter?
    @IBOutlet weak var finishButton: UIButton!
    @IBOutlet weak var videoView: UIView!
    private let disposeBag = DisposeBag()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.presenter = AutofillInstructionsPresenter(view: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupVideo()
        self.presenter?.onViewReady()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
}

extension AutofillInstructionsView: AutofillInstructionsViewProtocol {
    var finishButtonTapped: Observable<Void> {
        return self.finishButton.rx.tap.asObservable()
    }
}

extension AutofillInstructionsView {
    private func setupVideo() {
        guard let path = Bundle.main.url(forResource: "AutofillSetup_v1.4", withExtension: "mp4") else {
            return
        }

        let player = AVPlayer(url: path)
        let layer = AVPlayerLayer(player: player)
        layer.frame = self.videoView.bounds
        self.videoView.layer.addSublayer(layer)
        player.play()

        NotificationCenter.default.rx
            .notification(NSNotification.Name.AVPlayerItemDidPlayToEndTime)
            .subscribe({_ in
                player.seek(to: CMTime.zero)
                player.play()
            }).disposed(by: self.disposeBag)
    }
}

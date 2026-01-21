//
//  NoteAttachmentView+Video.swift
//  Kimis
//
//  Created by Lakr Aream on 2023/1/4.
//

import AVKit
import UIKit

extension NoteAttachmentView.Preview {
    class VideoView: UIView, AVPlayerViewControllerDelegate {
        var videoUrl: URL? {
            didSet {
                guard oldValue != videoUrl else { return }
                updatePlaybackItem()
            }
        }

        private let videoView = VideoPreviewLoopedPlayerView()

        var overlayIsShown = true
        let openFullButton = BlurButton(
            systemIcon: "arrow.up.left.and.arrow.down.right",
            tintColor: .white,
            effect: UIBlurEffect(style: .systemMaterialDark),
        )
        let openSafariButton = BlurButton(
            systemIcon: "safari",
            tintColor: .white,
            effect: UIBlurEffect(style: .systemMaterialDark),
        )
        let loadingIndicator = UIActivityIndicatorView()
        let mainButton = UIButton()

        init() {
            super.init(frame: .zero)

            loadingIndicator.startAnimating()
            addSubview(loadingIndicator)

            addSubview(videoView)
            addSubview(mainButton)
            addSubview(openFullButton)
            addSubview(openSafariButton)

            openFullButton.button.addTarget(
                self,
                action: #selector(presentPlayer),
                for: .touchUpInside,
            )
            openSafariButton.button.addTarget(
                self,
                action: #selector(openInSafari),
                for: .touchUpInside,
            )
            mainButton.addTarget(self, action: #selector(toggleOverlay), for: .touchUpInside)

            hideOverlay()
        }

        @available(*, unavailable)
        required init?(coder _: NSCoder) {
            fatalError()
        }

        override func layoutSubviews() {
            super.layoutSubviews()

            loadingIndicator.frame = CGRect(center: bounds.center, size: loadingIndicator.intrinsicContentSize)

            videoView.frame = bounds
            mainButton.frame = bounds

            let buttonInset: CGFloat = 8
            let buttonRadius: CGFloat = 4

            openFullButton.frame = CGRect(
                x: buttonInset, y: buttonInset,
                width: 40, height: 30,
            )
            openFullButton.layer.cornerRadius = buttonRadius

            openSafariButton.frame = CGRect(
                x: bounds.width - buttonInset - 40, y: buttonInset,
                width: 40, height: 30,
            )
            openSafariButton.layer.cornerRadius = buttonRadius
        }

        func updatePlaybackItem() {
            videoView.unload()
            guard let url = videoUrl, window != nil else {
                return
            }
            videoView.prepareVideo(url)
            videoView.play()
        }

        @objc func toggleOverlay() {
            if overlayIsShown {
                hideOverlay()
            } else {
                showOverlay()
            }
        }

        @objc func showOverlay() {
            overlayIsShown = true
            withUIKitAnimation {
                self.openFullButton.alpha = 1
                self.openSafariButton.alpha = 1
            }
        }

        @objc func hideOverlay() {
            overlayIsShown = false
            withUIKitAnimation {
                self.openFullButton.alpha = 0
                self.openSafariButton.alpha = 0
            }
        }

        @objc func presentPlayer() {
            guard let videoUrl else { return }
            let controller = AVPlayerViewController()
            controller.player = AVPlayer(url: videoUrl)
            controller.player?.isMuted = true
            controller.title = "🎥"
            controller.allowsPictureInPicturePlayback = true
            if #available(iOS 14.2, *) {
                controller.canStartPictureInPictureAutomaticallyFromInline = true
            }
            controller.showsPlaybackControls = true
            parentViewController?.present(controller, animated: true)
            controller.player?.play()
        }

        @objc func openInSafari() {
            guard let videoUrl else { return }
            UIApplication.shared.open(videoUrl)
        }
    }
}

private final class VideoPreviewLoopedPlayerView: UIView {
    fileprivate var videoURL: URL?
    fileprivate var queuePlayer: AVQueuePlayer?
    fileprivate var playerLayer: AVPlayerLayer?
    fileprivate var playbackLooper: AVPlayerLooper?

    init() {
        super.init(frame: .zero)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pause),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil,
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(play),
            name: UIApplication.willEnterForegroundNotification,
            object: nil,
        )
    }

    func prepareVideo(_ videoURL: URL) {
        let playerItem = AVPlayerItem(url: videoURL)
        self.queuePlayer = AVQueuePlayer(playerItem: playerItem)
        self.playerLayer = AVPlayerLayer(player: self.queuePlayer)
        guard let playerLayer else { return }
        guard let queuePlayer else { return }
        playbackLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
        queuePlayer.isMuted = true
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.frame = frame
        layer.addSublayer(playerLayer)
    }

    func unload() {
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        queuePlayer = nil
        playbackLooper = nil
    }

    @objc func play() {
        queuePlayer?.play()
    }

    @objc func pause() {
        queuePlayer?.pause()
    }

    @objc func stop() {
        queuePlayer?.pause()
        queuePlayer?.seek(to: CMTime(seconds: 0, preferredTimescale: 1))
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError()
    }

    override func layoutSubviews() {
        playerLayer?.frame = bounds
    }

    deinit {
        unload()
    }
}

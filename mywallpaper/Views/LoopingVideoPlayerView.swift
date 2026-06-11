//
//  LoopingVideoPlayerView.swift
//  mywallpaper
//

import AppKit
import AVFoundation
import SwiftUI

final class LoopingVideoNSView: NSView {
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private let playerLayer = AVPlayerLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        playerLayer.videoGravity = .resizeAspectFill
        playerLayer.backgroundColor = NSColor.black.cgColor
        layer?.addSublayer(playerLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }

    func configure(url: URL, muted: Bool) {
        cleanup()

        let templateItem = AVPlayerItem(url: url)
        let queuePlayer = AVQueuePlayer()
        queuePlayer.isMuted = muted
        queuePlayer.volume = 0
        queuePlayer.actionAtItemEnd = .none

        looper = AVPlayerLooper(player: queuePlayer, templateItem: templateItem)
        player = queuePlayer
        playerLayer.player = queuePlayer
        queuePlayer.play()
    }

    func pause() {
        player?.pause()
    }

    func play() {
        player?.play()
    }

    private func cleanup() {
        player?.pause()
        playerLayer.player = nil
        player = nil
        looper = nil
    }

    deinit {
        player?.pause()
    }
}

struct LoopingVideoPlayerView: NSViewRepresentable {
    let url: URL
    var muted = true
    var isPlaying = true

    func makeNSView(context: Context) -> LoopingVideoNSView {
        let view = LoopingVideoNSView(frame: .zero)
        view.configure(url: url, muted: muted)
        return view
    }

    func updateNSView(_ nsView: LoopingVideoNSView, context: Context) {
        if isPlaying {
            nsView.play()
        } else {
            nsView.pause()
        }
    }
}

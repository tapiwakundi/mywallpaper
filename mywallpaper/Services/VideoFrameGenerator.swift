//
//  VideoFrameGenerator.swift
//  mywallpaper
//

import AVFoundation
import AppKit

final class VideoFrameGenerator {
    private let generator: AVAssetImageGenerator
    private let duration: TimeInterval
    private var playbackStart = Date()

    init?(url: URL) {
        let asset = AVURLAsset(url: url)
        let durationSeconds = CMTimeGetSeconds(asset.duration)
        guard durationSeconds.isFinite, durationSeconds > 0 else { return nil }

        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = CMTime(seconds: 0.05, preferredTimescale: 600)
        imageGenerator.requestedTimeToleranceAfter = CMTime(seconds: 0.05, preferredTimescale: 600)

        generator = imageGenerator
        duration = durationSeconds
    }

    func resetPlaybackClock() {
        playbackStart = Date()
    }

    func currentFrameImage() -> NSImage? {
        let elapsed = Date().timeIntervalSince(playbackStart)
        let loopTime = elapsed.truncatingRemainder(dividingBy: duration)
        let cmTime = CMTime(seconds: loopTime, preferredTimescale: 600)

        guard let cgImage = try? generator.copyCGImage(at: cmTime, actualTime: nil) else {
            return nil
        }

        return NSImage(
            cgImage: cgImage,
            size: NSSize(width: cgImage.width, height: cgImage.height)
        )
    }
}

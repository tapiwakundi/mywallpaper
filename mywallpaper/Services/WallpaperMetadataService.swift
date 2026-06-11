//
//  WallpaperMetadataService.swift
//  mywallpaper
//

import AVFoundation
import Foundation

struct WallpaperMetadata: Sendable {
    let resolution: String
    let fileSize: String
    let duration: String
    let addedDescription: String

    var detailLine: String {
        [resolution, addedDescription, fileSize, duration].joined(separator: " • ")
    }
}

enum WallpaperMetadataService {
    static func load(for item: WallpaperItem) async -> WallpaperMetadata {
        guard let url = item.playbackURL() else {
            return WallpaperMetadata(resolution: "—", fileSize: "—", duration: "—", addedDescription: "—")
        }

        let fileSize = formattedFileSize(at: url)
        let addedDescription = formattedAddedDate(for: item)

        let asset = AVURLAsset(url: url)
        var resolution = "—"
        var duration = "—"

        if let track = try? await asset.loadTracks(withMediaType: .video).first {
            if let size = try? await track.load(.naturalSize) {
                let width = Int(abs(size.width))
                let height = Int(abs(size.height))
                resolution = "\(width)×\(height)"
            }
        }

        if let assetDuration = try? await asset.load(.duration) {
            let seconds = CMTimeGetSeconds(assetDuration)
            if seconds.isFinite, seconds > 0 {
                duration = formattedDuration(seconds)
            }
        }

        return WallpaperMetadata(
            resolution: resolution,
            fileSize: fileSize,
            duration: duration,
            addedDescription: addedDescription
        )
    }

    private static func formattedFileSize(at url: URL) -> String {
        guard
            let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
            let size = attributes[.size] as? Int64
        else {
            return "—"
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    private static func formattedDuration(_ seconds: Double) -> String {
        let total = Int(seconds.rounded())
        let minutes = total / 60
        let remainder = total % 60
        if minutes > 0 {
            return "\(minutes):\(String(format: "%02d", remainder))s"
        }
        return "0:\(String(format: "%02d", remainder))s"
    }

    private static func formattedAddedDate(for item: WallpaperItem) -> String {
        switch item {
        case .builtIn(let id):
            return "Included • \(id.credit)"
        case .custom(let custom):
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            return formatter.localizedString(for: custom.addedAt, relativeTo: .now)
        }
    }
}

//
//  CustomWallpaperStore.swift
//  mywallpaper
//

import Foundation

enum CustomWallpaperStoreError: LocalizedError {
    case unsupportedFormat
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .unsupportedFormat:
            "Only video files (MP4, MOV, M4V) are supported."
        case .copyFailed:
            "Could not save the video. Please try again."
        }
    }
}

struct CustomWallpaperStore: Sendable {
    static let videosDirectory: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("mywallpaper/Videos", isDirectory: true)
    }()

    private static let manifestURL: URL = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("mywallpaper/custom-wallpapers.json")
    }()

    private static let supportedExtensions = ["mp4", "mov", "m4v"]

    func loadWallpapers() -> [CustomWallpaper] {
        ensureDirectoriesExist()

        guard
            FileManager.default.fileExists(atPath: Self.manifestURL.path),
            let data = try? Data(contentsOf: Self.manifestURL),
            let wallpapers = try? JSONDecoder().decode([CustomWallpaper].self, from: data)
        else {
            return []
        }

        return wallpapers.filter { FileManager.default.fileExists(atPath: $0.fileURL.path) }
    }

    func saveWallpapers(_ wallpapers: [CustomWallpaper]) {
        ensureDirectoriesExist()
        guard let data = try? JSONEncoder().encode(wallpapers) else { return }
        try? data.write(to: Self.manifestURL, options: .atomic)
    }

    func importVideo(from sourceURL: URL) throws -> CustomWallpaper {
        ensureDirectoriesExist()

        let ext = sourceURL.pathExtension.lowercased()
        guard Self.supportedExtensions.contains(ext) else {
            throw CustomWallpaperStoreError.unsupportedFormat
        }

        let id = UUID()
        let fileName = "\(id.uuidString).\(ext)"
        let destination = Self.videosDirectory.appendingPathComponent(fileName)

        let accessed = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        do {
            if FileManager.default.fileExists(atPath: destination.path) {
                try FileManager.default.removeItem(at: destination)
            }
            try FileManager.default.copyItem(at: sourceURL, to: destination)
        } catch {
            throw CustomWallpaperStoreError.copyFailed
        }

        let name = sourceURL.deletingPathExtension().lastPathComponent
        return CustomWallpaper(id: id, name: name, fileName: fileName, addedAt: .now)
    }

    func deleteWallpaper(_ wallpaper: CustomWallpaper) {
        try? FileManager.default.removeItem(at: wallpaper.fileURL)
    }

    private func ensureDirectoriesExist() {
        try? FileManager.default.createDirectory(at: Self.videosDirectory, withIntermediateDirectories: true)
        let appSupport = Self.videosDirectory.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
    }
}

//
//  Wallpaper.swift
//  mywallpaper
//

import Foundation

enum BuiltInWallpaperID: String, Codable, CaseIterable, Identifiable, Sendable {
    case aurora
    case ocean
    case sunset
    case starfield
    case waterfall

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .aurora: "Aurora Borealis"
        case .ocean: "Ocean Waves"
        case .sunset: "Sunset Beach"
        case .starfield: "Milky Way"
        case .waterfall: "Forest Waterfall"
        }
    }

    var iconName: String {
        switch self {
        case .aurora: "sparkles"
        case .ocean: "water.waves"
        case .sunset: "sun.horizon.fill"
        case .starfield: "moon.stars.fill"
        case .waterfall: "leaf.fill"
        }
    }

    var subtitle: String {
        switch self {
        case .aurora: "Northern lights over mountain peaks"
        case .ocean: "Gentle waves rolling to shore"
        case .sunset: "Golden hour on a quiet beach"
        case .starfield: "Stars reflecting on a mountain lake"
        case .waterfall: "Water cascading through lush forest"
        }
    }

    var videoURL: URL? {
        Bundle.main.url(forResource: rawValue, withExtension: "mp4", subdirectory: "DefaultWallpapers")
            ?? Bundle.main.url(forResource: rawValue, withExtension: "mp4")
    }

    var credit: String {
        switch self {
        case .starfield: "Pexels"
        default: "Mixkit"
        }
    }
}

struct CustomWallpaper: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    let fileName: String
    let addedAt: Date

    var fileURL: URL {
        CustomWallpaperStore.videosDirectory.appendingPathComponent(fileName)
    }
}

enum WallpaperItem: Equatable, Sendable {
    case builtIn(BuiltInWallpaperID)
    case custom(CustomWallpaper)

    var id: String {
        switch self {
        case .builtIn(let id): "built-in-\(id.rawValue)"
        case .custom(let wallpaper): "custom-\(wallpaper.id.uuidString)"
        }
    }

    var displayName: String {
        switch self {
        case .builtIn(let id): id.displayName
        case .custom(let wallpaper): wallpaper.name
        }
    }

    func playbackURL() -> URL? {
        switch self {
        case .builtIn(let id):
            id.videoURL
        case .custom(let custom):
            custom.fileURL
        }
    }
}

struct SavedWallpaperSelection: Codable, Sendable {
    enum Kind: String, Codable, Sendable {
        case builtIn
        case custom
    }

    let kind: Kind
    let builtInID: BuiltInWallpaperID?
    let customID: UUID?

    private enum CodingKeys: String, CodingKey {
        case kind
        case builtInID
        case customID
    }

    init(kind: Kind, builtInID: BuiltInWallpaperID?, customID: UUID?) {
        self.kind = kind
        self.builtInID = builtInID
        self.customID = customID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        kind = try container.decode(Kind.self, forKey: .kind)
        customID = try container.decodeIfPresent(UUID.self, forKey: .customID)

        if let rawValue = try container.decodeIfPresent(String.self, forKey: .builtInID) {
            let migrated = rawValue == "midnight" ? BuiltInWallpaperID.waterfall.rawValue : rawValue
            builtInID = BuiltInWallpaperID(rawValue: migrated)
        } else {
            builtInID = nil
        }
    }
}

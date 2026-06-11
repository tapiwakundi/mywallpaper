//
//  WallpaperThumbnailCard.swift
//  mywallpaper
//

import SwiftUI

struct WallpaperThumbnailCard: View {
    let wallpaper: WallpaperItem
    let isActive: Bool
    var width: CGFloat? = 220
    var height: CGFloat = 140
    var onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                preview
                    .frame(maxWidth: .infinity)
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                LinearGradient(
                    colors: [.clear, .black.opacity(0.65)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(wallpaper.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(12)

                if isActive {
                    VStack {
                        HStack {
                            Spacer()
                            Label("Active", systemImage: "checkmark.circle.fill")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .glassEffect(.regular.tint(.white.opacity(0.15)), in: .capsule)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isActive ? Color.white.opacity(0.9) : Color.white.opacity(0.08), lineWidth: isActive ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }

    @ViewBuilder
    private var preview: some View {
        if shouldPlayVideo, let url = wallpaper.playbackURL() {
            LoopingVideoPlayerView(url: url, muted: true, isPlaying: true)
                .background(Color.black)
        } else {
            WallpaperPlaceholderView(wallpaper: wallpaper)
        }
    }

    private var shouldPlayVideo: Bool {
        isActive || isHovered
    }
}

private struct WallpaperPlaceholderView: View {
    let wallpaper: WallpaperItem

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Image(systemName: iconName)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(.white.opacity(0.35))
        }
    }

    private var iconName: String {
        switch wallpaper {
        case .builtIn(let id): id.iconName
        case .custom: "film"
        }
    }

    private var gradientColors: [Color] {
        switch wallpaper {
        case .builtIn(let id):
            switch id {
            case .aurora: [Color(red: 0.05, green: 0.15, blue: 0.25), Color(red: 0.1, green: 0.3, blue: 0.2)]
            case .ocean: [Color(red: 0.02, green: 0.12, blue: 0.28), Color(red: 0.0, green: 0.2, blue: 0.35)]
            case .sunset: [Color(red: 0.35, green: 0.12, blue: 0.08), Color(red: 0.15, green: 0.05, blue: 0.2)]
            case .starfield: [Color(red: 0.02, green: 0.02, blue: 0.1), Color(red: 0.08, green: 0.06, blue: 0.2)]
            case .waterfall: [Color(red: 0.04, green: 0.12, blue: 0.1), Color(red: 0.08, green: 0.2, blue: 0.15)]
            }
        case .custom:
            [Color(red: 0.12, green: 0.12, blue: 0.16), Color(red: 0.2, green: 0.18, blue: 0.24)]
        }
    }
}

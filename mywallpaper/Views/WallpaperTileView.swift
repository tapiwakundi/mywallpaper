//
//  WallpaperTileView.swift
//  mywallpaper
//

import SwiftUI

struct WallpaperTileView: View {
    let wallpaper: WallpaperItem
    let isActive: Bool
    let onApply: () -> Void
    var onDelete: (() -> Void)?

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                preview
                    .frame(maxWidth: .infinity)
                    .frame(height: 140)
                    .background(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isActive ? Color.accentColor : Color.primary.opacity(0.1), lineWidth: isActive ? 3 : 1)
                    }

                if isActive {
                    Label("Active", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(8)
                }
            }

            HStack {
                Label(wallpaper.displayName, systemImage: iconName)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                Spacer()

                if let onDelete, isHovered {
                    Button(role: .destructive, action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .help("Delete video")
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onApply)
        .onHover { isHovered = $0 }
        .animation(.easeInOut(duration: 0.15), value: isHovered)
    }

    @ViewBuilder
    private var preview: some View {
        switch wallpaper {
        case .builtIn(let id):
            if let url = id.videoURL {
                LoopingVideoPlayerView(url: url, muted: true)
            } else {
                ContentUnavailableView("Missing Video", systemImage: "exclamationmark.triangle")
            }
        case .custom(let custom):
            LoopingVideoPlayerView(url: custom.fileURL, muted: true)
        }
    }

    private var iconName: String {
        switch wallpaper {
        case .builtIn(let id):
            id.iconName
        case .custom:
            "film"
        }
    }
}

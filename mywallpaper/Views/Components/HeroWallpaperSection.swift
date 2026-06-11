//
//  HeroWallpaperSection.swift
//  mywallpaper
//

import SwiftUI

struct HeroWallpaperSection: View {
    let wallpapers: [WallpaperItem]
    @Binding var featuredIndex: Int
    @Binding var favorites: Set<String>
    let isActive: (WallpaperItem) -> Bool
    let metadata: WallpaperMetadata?
    var topSafeAreaInset: CGFloat = 0
    var onApply: (WallpaperItem) -> Void

    var body: some View {
        ZStack {
            if let wallpaper = featuredWallpaper {
                heroSlide(for: wallpaper)
                    .id(wallpaper.id)
                    .transition(.opacity)
            } else {
                Color.black
            }

            HStack {
                carouselButton(systemName: "chevron.left") {
                    stepFeatured(by: -1)
                }
                Spacer()
                carouselButton(systemName: "chevron.right") {
                    stepFeatured(by: 1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, topSafeAreaInset)

            VStack {
                LinearGradient(
                    colors: [.black.opacity(0.5), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: topSafeAreaInset + 72)
                Spacer()
            }
            .allowsHitTesting(false)

            VStack {
                Spacer()
                heroOverlay
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
            }

            if wallpapers.count > 1 {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        ForEach(wallpapers.indices, id: \.self) { index in
                            Circle()
                                .fill(index == featuredIndex ? Color.white : Color.white.opacity(0.35))
                                .frame(width: index == featuredIndex ? 7 : 5, height: index == featuredIndex ? 7 : 5)
                        }
                    }
                    .padding(.bottom, 10)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .animation(.easeInOut(duration: 0.35), value: featuredIndex)
    }

    private var featuredWallpaper: WallpaperItem? {
        guard wallpapers.indices.contains(featuredIndex) else { return nil }
        return wallpapers[featuredIndex]
    }

    @ViewBuilder
    private func heroSlide(for wallpaper: WallpaperItem) -> some View {
        if let url = wallpaper.playbackURL() {
            LoopingVideoPlayerView(url: url, muted: true, isPlaying: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .overlay {
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.2), .black.opacity(0.88)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }
        } else {
            Color.black
        }
    }

    private var heroOverlay: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                if let wallpaper = featuredWallpaper {
                    Text(wallpaper.category)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.55))

                    Text(wallpaper.displayName)
                        .font(.system(size: 38, weight: .regular, design: .serif))
                        .foregroundStyle(.white)

                    if let metadata {
                        Text(metadata.detailLine)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.5))
                    }

                    GlassEffectContainer(spacing: 10) {
                        HStack(spacing: 10) {
                            Button {
                                onApply(wallpaper)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: isActive(wallpaper) ? "checkmark.circle.fill" : "play.fill")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text(isActive(wallpaper) ? "Wallpaper Active" : "Set Wallpaper")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 22)
                                .padding(.vertical, 12)
                                .glassEffect(.regular.tint(.white.opacity(0.22)).interactive(), in: .capsule)
                            }
                            .buttonStyle(.plain)

                            Button {
                                toggleFavorite(wallpaper)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: favorites.contains(wallpaper.id) ? "heart.fill" : "heart")
                                        .font(.system(size: 13, weight: .medium))
                                    Text("\(favoriteCount(for: wallpaper))")
                                        .font(.system(size: 13, weight: .medium))
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .glassEffect(.regular.interactive(), in: .capsule)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, 4)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func carouselButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .frame(width: 36, height: 36)
                .glassCircle()
        }
        .buttonStyle(.plain)
        .opacity(wallpapers.count > 1 ? 1 : 0)
        .disabled(wallpapers.count <= 1)
    }

    private func stepFeatured(by offset: Int) {
        guard !wallpapers.isEmpty else { return }
        featuredIndex = (featuredIndex + offset + wallpapers.count) % wallpapers.count
    }

    private func toggleFavorite(_ wallpaper: WallpaperItem) {
        if favorites.contains(wallpaper.id) {
            favorites.remove(wallpaper.id)
        } else {
            favorites.insert(wallpaper.id)
        }
    }

    private func favoriteCount(for wallpaper: WallpaperItem) -> Int {
        let base = abs(wallpaper.id.hashValue % 400) + 120
        return favorites.contains(wallpaper.id) ? base + 1 : base
    }
}

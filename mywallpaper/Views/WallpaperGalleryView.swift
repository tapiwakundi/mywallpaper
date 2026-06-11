//
//  WallpaperGalleryView.swift
//  mywallpaper
//

import SwiftUI
import UniformTypeIdentifiers

struct WallpaperGalleryView: View {
    @Environment(WallpaperManager.self) private var manager

    @State private var isImporting = false
    @State private var showStopConfirmation = false

    private let columns = [
        GridItem(.adaptive(minimum: 200, maximum: 260), spacing: 16)
    ]

    var body: some View {
        @Bindable var manager = manager

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    statusBanner

                    if let error = manager.lastError {
                        Text(error)
                            .font(.callout)
                            .foregroundStyle(.red)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }

                    wallpaperSection(
                        title: "Built-in Live Wallpapers",
                        subtitle: "Cinematic loops from Mixkit & Pexels (free licenses)"
                    ) {
                        ForEach(BuiltInWallpaperID.allCases) { id in
                            WallpaperTileView(
                                wallpaper: .builtIn(id),
                                isActive: manager.activeWallpaper == .builtIn(id),
                                onApply: { manager.apply(.builtIn(id)) }
                            )
                        }
                    }

                    wallpaperSection(
                        title: "Your Videos",
                        subtitle: "Upload MP4, MOV, or M4V files from your Mac"
                    ) {
                        uploadTile

                        if manager.customWallpapers.isEmpty {
                            emptyCustomState
                        } else {
                            ForEach(manager.customWallpapers) { custom in
                                WallpaperTileView(
                                    wallpaper: .custom(custom),
                                    isActive: manager.activeWallpaper == .custom(custom),
                                    onApply: { manager.apply(.custom(custom)) },
                                    onDelete: { manager.deleteCustomWallpaper(custom) }
                                )
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("MyWallpaper")
            .toolbar {
                ToolbarItemGroup {
                    if manager.isWallpaperActive {
                        Button("Stop Wallpaper") {
                            showStopConfirmation = true
                        }
                    }

                    Button {
                        isImporting = true
                    } label: {
                        Label("Upload Video", systemImage: "square.and.arrow.up")
                    }

                    Toggle(isOn: $manager.showOnLockScreen) {
                        Label("Show on Lock Screen", systemImage: "lock.display")
                    }
                    .toggleStyle(.checkbox)
                    .onChange(of: manager.showOnLockScreen) { _, newValue in
                        manager.setShowOnLockScreen(newValue)
                    }

                    Toggle(isOn: $manager.launchAtLogin) {
                        Label("Launch at Login", systemImage: "power")
                    }
                    .toggleStyle(.checkbox)
                    .onChange(of: manager.launchAtLogin) { _, newValue in
                        manager.setLaunchAtLogin(newValue)
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie, .video],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    guard let url = urls.first else { return }
                    Task {
                        await manager.importVideo(from: url)
                    }
                case .failure:
                    manager.lastError = "Could not open the selected file."
                }
            }
            .confirmationDialog(
                "Stop live wallpaper?",
                isPresented: $showStopConfirmation,
                titleVisibility: .visible
            ) {
                Button("Stop Wallpaper", role: .destructive) {
                    manager.stopWallpaper()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your desktop will return to its previous static wallpaper.")
            }
        }
    }

    @ViewBuilder
    private var statusBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: manager.isWallpaperActive ? "play.circle.fill" : "pause.circle")
                .font(.title2)
                .foregroundStyle(manager.isWallpaperActive ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(manager.isWallpaperActive ? "Live wallpaper is running" : "No live wallpaper active")
                    .font(.headline)
                Text(
                    manager.isWallpaperActive
                        ? "Showing \"\(manager.activeWallpaper?.displayName ?? "")\" on your desktop\(manager.showOnLockScreen ? " and lock screen" : ""). Keep this app running."
                        : "Choose a wallpaper below or upload your own video."
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var uploadTile: some View {
        Button {
            isImporting = true
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                Text("Upload Video")
                    .font(.subheadline.weight(.semibold))
                Text("MP4 · MOV · M4V")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    .foregroundStyle(Color.accentColor.opacity(0.4))
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyCustomState: some View {
        Text("No custom videos yet. Upload one to get started.")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .gridCellColumns(2)
    }

    private func wallpaperSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: columns, spacing: 16) {
                content()
            }
        }
    }
}

#Preview {
    WallpaperGalleryView()
        .environment(WallpaperManager.shared)
        .frame(width: 900, height: 700)
}

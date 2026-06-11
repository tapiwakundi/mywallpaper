//
//  WallpaperGalleryView.swift
//  mywallpaper
//

import SwiftUI
import UniformTypeIdentifiers

struct WallpaperGalleryView: View {
    @Environment(WallpaperManager.self) private var manager

    @State private var selectedTab: AppTab = .home
    @State private var searchText = ""
    @State private var featuredIndex = 0
    @State private var favorites: Set<String> = []
    @State private var heroMetadata: WallpaperMetadata?
    @State private var isImporting = false
    @State private var showSettings = false

    @AppStorage("favoriteWallpaperIDs") private var favoriteStorage = ""

    private let edgeInset: CGFloat = 12
    private let gridColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
    ]

    var body: some View {
        Group {
            switch selectedTab {
            case .home:
                homeContent
            case .explore:
                gridTabContent(wallpapers: filteredBuiltInWallpapers.map(WallpaperItem.builtIn))
            case .myMedia:
                myMediaContent
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                ToolbarSearchField(searchText: $searchText)
            }
            ToolbarItem(placement: .principal) {
                ToolbarTabPicker(selectedTab: $selectedTab)
            }
            ToolbarItemGroup(placement: .primaryAction) {
                ToolbarActionButtons(
                    onUpload: { isImporting = true },
                    onSettings: { showSettings = true }
                )
            }
        }
        .toolbar(removing: .title)
        .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        .preferredColorScheme(.dark)
        .task {
            favorites = Self.loadFavorites(from: favoriteStorage)
            await loadHeroMetadata()
        }
        .onChange(of: favorites) { _, newValue in
            favoriteStorage = newValue.sorted().joined(separator: ",")
        }
        .onChange(of: featuredIndex) { _, _ in
            Task { await loadHeroMetadata() }
        }
        .onChange(of: filteredWallpapers.count) { _, _ in
            featuredIndex = min(featuredIndex, max(filteredWallpapers.count - 1, 0))
        }
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.movie, .mpeg4Movie, .quickTimeMovie, .video],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                Task { await manager.importVideo(from: url) }
            case .failure:
                manager.lastError = "Could not open the selected file."
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
                .environment(manager)
        }
    }

    // MARK: - Home

    private var homeContent: some View {
        GeometryReader { geometry in
            let topInset = geometry.safeAreaInsets.top

            ScrollView {
                VStack(spacing: 0) {
                    HeroWallpaperSection(
                        wallpapers: filteredWallpapers,
                        featuredIndex: $featuredIndex,
                        favorites: $favorites,
                        isActive: isActive,
                        metadata: heroMetadata,
                        topSafeAreaInset: topInset,
                        onApply: { manager.apply($0) }
                    )
                    .frame(height: 480 + topInset)
                    .padding(.top, -topInset)

                    recommendedSection
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
        }
    }

    private var recommendedSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Text("Recommended For You")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.45))
                Spacer()
            }
            .padding(.horizontal, edgeInset)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(recommendedWallpapers) { wallpaper in
                        WallpaperThumbnailCard(
                            wallpaper: wallpaper,
                            isActive: isActive(wallpaper),
                            width: 220,
                            height: 140,
                            onTap: {
                                manager.apply(wallpaper)
                                if let index = filteredWallpapers.firstIndex(where: { $0.id == wallpaper.id }) {
                                    featuredIndex = index
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, edgeInset)
            }
        }
    }

    // MARK: - Grid tabs

    private func gridTabContent(wallpapers: [WallpaperItem]) -> some View {
        ScrollView {
            LazyVGrid(columns: gridColumns, spacing: 10) {
                ForEach(wallpapers) { wallpaper in
                    WallpaperThumbnailCard(
                        wallpaper: wallpaper,
                        isActive: isActive(wallpaper),
                        width: nil,
                        height: 150,
                        onTap: { manager.apply(wallpaper) }
                    )
                }
            }
            .padding(.horizontal, edgeInset)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var myMediaContent: some View {
        ScrollView {
            if filteredCustomWallpapers.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.25))
                    Text("No videos yet")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("Upload MP4, MOV, or M4V files to use as live wallpapers.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.center)
                    Button("Upload Video") { isImporting = true }
                        .buttonStyle(.glass)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 120)
                .padding(.horizontal, edgeInset)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 10) {
                    uploadCard

                    ForEach(filteredCustomWallpapers) { custom in
                        let wallpaper = WallpaperItem.custom(custom)
                        WallpaperThumbnailCard(
                            wallpaper: wallpaper,
                            isActive: isActive(wallpaper),
                            width: nil,
                            height: 150,
                            onTap: { manager.apply(wallpaper) }
                        )
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                manager.deleteCustomWallpaper(custom)
                            }
                        }
                    }
                }
                .padding(.horizontal, edgeInset)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var uploadCard: some View {
        Button { isImporting = true } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(.white.opacity(0.75))
                Text("Upload Video")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 150)
            .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6, 4]))
                    .foregroundStyle(.white.opacity(0.2))
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Data

    private var allWallpapers: [WallpaperItem] {
        BuiltInWallpaperID.allCases.map(WallpaperItem.builtIn)
            + manager.customWallpapers.map(WallpaperItem.custom)
    }

    private var filteredWallpapers: [WallpaperItem] {
        filter(allWallpapers)
    }

    private var filteredBuiltInWallpapers: [BuiltInWallpaperID] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return BuiltInWallpaperID.allCases }
        return BuiltInWallpaperID.allCases.filter {
            $0.displayName.lowercased().contains(query)
                || $0.category.lowercased().contains(query)
        }
    }

    private var filteredCustomWallpapers: [CustomWallpaper] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return manager.customWallpapers }
        return manager.customWallpapers.filter { $0.name.lowercased().contains(query) }
    }

    private var recommendedWallpapers: [WallpaperItem] {
        Array(filteredWallpapers.prefix(8))
    }

    private func filter(_ items: [WallpaperItem]) -> [WallpaperItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.displayName.lowercased().contains(query)
                || $0.category.lowercased().contains(query)
        }
    }

    private func isActive(_ wallpaper: WallpaperItem) -> Bool {
        manager.activeWallpaper == wallpaper
    }

    private func loadHeroMetadata() async {
        guard filteredWallpapers.indices.contains(featuredIndex) else {
            heroMetadata = nil
            return
        }
        heroMetadata = await WallpaperMetadataService.load(for: filteredWallpapers[featuredIndex])
    }

    private static func loadFavorites(from storage: String) -> Set<String> {
        Set(storage.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }
}

#Preview {
    WallpaperGalleryView()
        .environment(WallpaperManager.shared)
        .frame(width: 980, height: 720)
}

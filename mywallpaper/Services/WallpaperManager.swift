//
//  WallpaperManager.swift
//  mywallpaper
//

import Foundation
import Observation
import ServiceManagement

@Observable
@MainActor
final class WallpaperManager {
    static let shared = WallpaperManager()

    private(set) var activeWallpaper: WallpaperItem?
    private(set) var customWallpapers: [CustomWallpaper] = []
    var launchAtLogin = false
    var lastError: String?

    private let desktopController = DesktopWallpaperController()
    private let systemWallpaperController = SystemWallpaperController()
    private let store = CustomWallpaperStore()
    private let selectionKey = "activeWallpaperSelection"
    private let lockScreenKey = "showOnLockScreen"

    var showOnLockScreen = true

    private init() {
        customWallpapers = store.loadWallpapers()
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
        showOnLockScreen = UserDefaults.standard.object(forKey: lockScreenKey) as? Bool ?? true
        restoreSavedWallpaper()
    }

    var isWallpaperActive: Bool {
        activeWallpaper != nil
    }

    func apply(_ wallpaper: WallpaperItem) {
        lastError = nil
        activeWallpaper = wallpaper
        desktopController.apply(wallpaper)

        if showOnLockScreen, let url = wallpaper.playbackURL() {
            systemWallpaperController.start(url: url)
        } else {
            systemWallpaperController.stop(restoreSaved: true)
        }

        saveSelection(wallpaper)
    }

    func stopWallpaper() {
        lastError = nil
        activeWallpaper = nil
        desktopController.stop()
        systemWallpaperController.stop(restoreSaved: true)
        UserDefaults.standard.removeObject(forKey: selectionKey)
    }

    func setShowOnLockScreen(_ enabled: Bool) {
        showOnLockScreen = enabled
        UserDefaults.standard.set(enabled, forKey: lockScreenKey)

        guard let wallpaper = activeWallpaper else { return }

        if enabled, let url = wallpaper.playbackURL() {
            systemWallpaperController.start(url: url)
        } else {
            systemWallpaperController.stop(restoreSaved: true)
        }
    }

    func importVideo(from url: URL) async {
        lastError = nil
        do {
            let wallpaper = try store.importVideo(from: url)
            customWallpapers.insert(wallpaper, at: 0)
            store.saveWallpapers(customWallpapers)
            apply(.custom(wallpaper))
        } catch {
            lastError = error.localizedDescription
        }
    }

    func deleteCustomWallpaper(_ wallpaper: CustomWallpaper) {
        lastError = nil
        if case .custom(let active) = activeWallpaper, active.id == wallpaper.id {
            stopWallpaper()
        }
        store.deleteWallpaper(wallpaper)
        customWallpapers.removeAll { $0.id == wallpaper.id }
        store.saveWallpapers(customWallpapers)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            launchAtLogin = enabled
        } catch {
            lastError = "Could not update Launch at Login."
            launchAtLogin = (SMAppService.mainApp.status == .enabled)
        }
    }

    private func restoreSavedWallpaper() {
        guard
            let data = UserDefaults.standard.data(forKey: selectionKey),
            let selection = try? JSONDecoder().decode(SavedWallpaperSelection.self, from: data)
        else {
            return
        }

        switch selection.kind {
        case .builtIn:
            guard let id = selection.builtInID else { return }
            apply(.builtIn(id))
        case .custom:
            guard
                let id = selection.customID,
                let wallpaper = customWallpapers.first(where: { $0.id == id })
            else {
                return
            }
            apply(.custom(wallpaper))
        }
    }

    private func saveSelection(_ wallpaper: WallpaperItem) {
        let selection: SavedWallpaperSelection
        switch wallpaper {
        case .builtIn(let id):
            selection = SavedWallpaperSelection(kind: .builtIn, builtInID: id, customID: nil)
        case .custom(let custom):
            selection = SavedWallpaperSelection(kind: .custom, builtInID: nil, customID: custom.id)
        }

        if let data = try? JSONEncoder().encode(selection) {
            UserDefaults.standard.set(data, forKey: selectionKey)
        }
    }
}

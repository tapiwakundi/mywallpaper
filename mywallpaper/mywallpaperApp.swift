//
//  mywallpaperApp.swift
//  mywallpaper
//

import SwiftUI

@main
struct mywallpaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var manager = WallpaperManager.shared

    var body: some Scene {
        MenuBarExtra("MyWallpaper", systemImage: "photo.on.rectangle.angled") {
            MenuBarControlsView()
                .environment(manager)
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct MenuBarControlsView: View {
    @Environment(WallpaperManager.self) private var manager

    var body: some View {
        Group {
            if manager.isWallpaperActive {
                Button("Stop Wallpaper") {
                    manager.stopWallpaper()
                }
            }

            Button("Open MyWallpaper") {
                MainWindowController.shared.show()
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }
}

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
        WindowGroup {
            ContentView()
                .environment(manager)
        }
        .defaultSize(width: 900, height: 640)

        MenuBarExtra("MyWallpaper", systemImage: "photo.on.rectangle.angled") {
            MenuBarControlsView()
                .environment(manager)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarControlsView: View {
    @Environment(WallpaperManager.self) private var manager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if manager.isWallpaperActive {
                Text("Active: \(manager.activeWallpaper?.displayName ?? "")")
                    .font(.headline)
                Button("Stop Wallpaper") {
                    manager.stopWallpaper()
                }
            } else {
                Text("No wallpaper active")
                    .font(.headline)
                Text("Open MyWallpaper to choose one.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Open MyWallpaper") {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeMain {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding(16)
        .frame(width: 240)
    }
}

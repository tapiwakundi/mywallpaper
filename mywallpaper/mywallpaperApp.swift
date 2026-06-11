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
        .defaultSize(width: 1100, height: 760)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))

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
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.canBecomeMain {
                    window.makeKeyAndOrderFront(nil)
                    break
                }
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }
}

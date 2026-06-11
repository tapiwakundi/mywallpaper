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
        WindowGroup(id: "main") {
            ContentView()
                .environment(manager)
        }
        .defaultSize(width: 1100, height: 760)
        .defaultLaunchBehavior(.suppressed)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))

        MenuBarExtra("MyWallpaper", systemImage: "photo.on.rectangle.angled") {
            MenuBarControlsView()
                .environment(manager)
                .background(MenuBarWindowOpener())
        }
        .menuBarExtraStyle(.menu)
    }
}

private struct MenuBarWindowOpener: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                (NSApp.delegate as? AppDelegate)?.openMainWindowAction = {
                    openWindow(id: "main")
                }
            }
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
                (NSApp.delegate as? AppDelegate)?.showMainWindow()
            }

            Divider()

            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
    }
}

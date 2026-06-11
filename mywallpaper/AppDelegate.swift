//
//  AppDelegate.swift
//  mywallpaper
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var openMainWindowAction: (() -> Void)?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        Task { @MainActor in
            WallpaperManager.shared.finishLaunching()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard WallpaperManager.shared.isWallpaperActive else {
            return .terminateNow
        }

        let alert = NSAlert()
        alert.messageText = "Stop live wallpaper?"
        alert.informativeText = "Quitting MyWallpaper will stop your live wallpaper on the desktop and lock screen, and restore your previous wallpaper."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Quit and Stop Wallpaper")
        alert.addButton(withTitle: "Keep Running")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            WallpaperManager.shared.stopWallpaper()
            return .terminateNow
        }
        return .terminateCancel
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
        return true
    }

    @MainActor
    private func configureWindows() {
        for window in NSApp.windows where window.canBecomeMain {
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.styleMask.insert(.fullSizeContentView)
            window.isMovableByWindowBackground = true
            window.backgroundColor = .black
        }
    }

    @MainActor
    func showMainWindow() {
        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)
        configureWindows()

        if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
            window.makeKeyAndOrderFront(nil)
            return
        }

        openMainWindowAction?()
    }
}
